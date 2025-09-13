import json
import re
from flask import Flask, request, render_template, redirect, url_for, flash, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import func

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///linguist.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.secret_key = 'secret_key'
db = SQLAlchemy(app)


class User(db.Model):
    """
    Represents a user in the system.
    """
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)
    confirm_password = db.Column(db.String(120), nullable=False)
    decks = db.relationship('Deck', backref='user', lazy=True)

    def __repr__(self):
        """
        Represents a string version of the User object.

        Returns:
            str: A string representation of the User object with name and email.
        """
        return f"<User {self.name}, {self.email}>"


class Deck(db.Model):
    """
    Represents a deck in the system.
    """
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    cards = db.relationship('Card', backref='deck', lazy=True)

    def __repr__(self):
        """
        Represents a string version of the Deck object.

        Returns:
            str: A string representation of the Deck object with id and name.
        """
        return f"<Deck {self.id}, {self.name}>"


class Card(db.Model):
    """
    Represents a card in the system.

    Attributes:
        id (int): The unique identifier for the card.
        word (str): The word in English.
        translation (str): The translation of the word in Ukrainian.
        tip (str): A helpful tip or description for the card.
        deck_id (int): The ID of the deck to which the card belongs.
    """
    id = db.Column(db.Integer, primary_key=True)
    word = db.Column(db.String(80), nullable=False)
    translation = db.Column(db.String(100), nullable=False)
    tip = db.Column(db.String(120))
    deck_id = db.Column(db.Integer, db.ForeignKey('deck.id'), nullable=False)


@app.route('/', methods=['GET'])
def index():
    """
    Displays the table of users on the main page.
    """
    users = User.query.all()
    return render_template('index.html', users_list=users)


@app.route('/users/create', methods=['POST', 'GET'])
def create_user():
    """
    Creates a new user and validates the form in real-time for unique email.
    """
    errors = {}

    if request.method == 'POST':
        data = request.form
        name = data.get('name')
        email = data.get('email')
        password = data.get('password')
        confirm_password = data.get('confirm_password')

        # Перевірка унікальності email для AJAX-запитів
        if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
            existing_user = db.session.query(User).filter_by(email=email).first()
            if existing_user:
                errors['email'] = 'Email already exists. Please use a different email.'

        # Перевірка на обов'язкові поля
        if not name:
            errors['name'] = 'Name is required.'
        if not email:
            errors['email'] = 'Email is required.'
        if not password:
            errors['password'] = 'Password is required.'
        if not confirm_password:
            errors['confirm_password'] = 'Please confirm your password.'

        # Перевірка формату email
        email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if email and not re.match(email_regex, email):
            return jsonify({'error': 'Invalid email format.'}), 400

        # Перевірка, чи паролі співпадають
        if password != confirm_password:
            errors['confirm_password'] = 'Passwords do not match.'

        # Якщо є помилки, повертаємо їх до форми
        if errors:
            return render_template('create_user.html', errors=errors, data=data)

        # Створюємо нового користувача
        new_user = User(name=name, email=email, password=password, confirm_password=confirm_password)
        db.session.add(new_user)
        db.session.commit()

        flash('User created successfully!', 'success')
        return redirect(url_for('index'))

    return render_template('create_user.html', errors={}, data={})


@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """
    Retrieves a user by ID and returns an HTML page displaying the user object.
    """
    user = db.session.get(User, user_id)  # Updated
    if user:
        return render_template('user_details.html', user=user)
    return render_template('error.html', error='User not found')


@app.route('/users/<int:user_id>/name', methods=['PUT'])
def update_user_name(user_id):
    """
    Updates the name of a user and returns a JSON response.
    """
    data = request.get_json()
    new_name = data.get('name')

    if not new_name:
        return jsonify({"error": "Missing name"}), 400

    user = db.session.get(User, user_id)
    if user:
        user.name = new_name
        db.session.commit()

        return render_template('user_row.html', user=user)

    return render_template('error.html', message="User not found"), 404


@app.route('/users/<int:user_id>/password', methods=['PUT'])
def change_user_password(user_id):
    """
    Changes the password of a user.
    """
    data = request.get_json()
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    if not current_password or not new_password:
        return jsonify({"error": "Missing current or new password"}), 400

    user = db.session.get(User, user_id)
    if user:
        # Compare plain text passwords (NOT RECOMMENDED)
        if user.password != current_password:
            return jsonify({"error": "Current password is incorrect"}), 400

        if len(new_password) < 6:
            return jsonify({"error": "Password must be at least 6 characters long"}), 400

        # Update to the new plain text password (NOT RECOMMENDED)
        user.password = new_password
        db.session.commit()

        return jsonify({"message": "Password updated successfully"}), 200

    return jsonify({"error": "User not found"}), 404


@app.route('/users/<int:user_id>', methods=['POST'])
def delete_user(user_id):
    """
    Deletes a user by ID using POST with _method=DELETE and returns the user list page.
    """
    if request.form.get('_method') == 'DELETE':
        user = db.session.get(User, user_id)  # Updated
        if user:
            db.session.delete(user)
            db.session.commit()
            return redirect('/')

    return render_template('error.html', message="User not found"), 404


@app.route('/decks', methods=['GET'])
def list_decks():
    """
    Displays all decks for the current user.
    """
    decks = Deck.query.all()
    return render_template('decks.html', decks_list=decks)


@app.route('/decks/user/<int:user_id>', methods=['GET'])
def list_decks_by_user_id(user_id):
    """
    Displays a table of decks for a specific user.
    """
    decks = Deck.query.filter_by(user_id=user_id).all()
    return render_template('user_decks.html', decks_list=decks, user_id=user_id)


@app.route('/decks/<int:deck_id>', methods=['GET'])
def deck_get_by_id(deck_id):
    """
    Retrieves a deck by its ID and returns the Deck object.
    """
    deck = Deck.query.get(deck_id)
    if deck:
        return render_template('deck_details.html', deck=deck, cards=deck.cards)
    flash('Deck not found!', 'danger')
    return redirect(url_for('list_decks'))


@app.route('/decks/<int:deck_id>/delete', methods=['POST'])
def deck_delete_by_id(deck_id):
    """
    Deletes a deck by its ID and also deletes all cards associated with the deck.
    """
    deck = Deck.query.get(deck_id)
    if deck:
        # Видаляємо всі картки, що належать до цієї колоди
        cards = Card.query.filter_by(deck_id=deck.id).all()
        for card in cards:
            db.session.delete(card)

        # Видаляємо саму колоду
        db.session.delete(deck)
        db.session.commit()

        flash('Deck and its cards deleted successfully!', 'success')
        return redirect(url_for('list_decks'))

    flash('Deck not found!', 'danger')
    return redirect(url_for('list_decks'))


@app.route('/decks/create', methods=['POST', 'GET'])
def deck_create():
    """
    Creates a new deck for a user and redirects to the user's deck list page.
    """
    user_id = request.form.get('user_id')  # Отримуємо user_id з форми, якщо це POST-запит
    if not user_id:
        user_id = request.args.get('user_id')  # Або з параметрів URL, якщо це GET-запит

    if not user_id:
        flash('User ID is required.', 'danger')
        return redirect(url_for('list_decks'))  # Перенаправляємо, якщо немає user_id

    user = User.query.get(user_id)  # Перевіряємо, чи існує користувач
    if not user:
        flash('User not found.', 'danger')
        return redirect(url_for('list_decks'))

    if request.method == 'POST':
        data = request.form
        deck_name = data.get('name')
        cards_data = data.get('cards')

        if not deck_name:
            flash('Deck name is required.', 'danger')
            return redirect(request.url)

        # Перетворення JSON-строки в Python-об'єкт
        cards = json.loads(cards_data)

        # Створюємо нову колоду
        deck = Deck(name=deck_name, user_id=user_id)
        db.session.add(deck)
        db.session.commit()

        for card in cards:
            new_card = Card(
                deck_id=deck.id,
                word=card['word'],
                translation=card['translation'],
                tip=card['tip']
            )
            db.session.add(new_card)

        db.session.commit()

        flash('Deck created successfully!', 'success')

        # Перенаправляємо на список деків цього користувача
        return redirect(url_for('list_decks_by_user_id', user_id=user.id))

    # Якщо GET-запит, рендеримо форму
    return render_template('create_deck.html', user_id=user.id)


@app.route('/cards', methods=['GET'])
def list_cards():
    """
    Displays a table of all cards.
    """
    cards = Card.query.all()
    return render_template('cards.html', cards=cards)


@app.route('/decks/<int:deck_id>/cards/create', methods=['POST', 'GET'])
def create_card(deck_id):
    """
    Creates a new card in the specified deck.
    """
    deck = Deck.query.get(deck_id)
    if not deck:
        flash('Deck not found.', 'danger')
        return redirect(url_for('list_decks'))

    if request.method == 'POST':
        data = request.form
        word = data.get('word')
        translation = data.get('translation')
        tip = data.get('tip', None)

        if not word or not translation:
            flash('Word and translation are required.', 'danger')
            return redirect(request.url)

        new_card = Card(word=word, translation=translation, tip=tip, deck_id=deck_id)
        db.session.add(new_card)
        db.session.commit()

        flash('Card created successfully!', 'success')
        return redirect(url_for('deck_get_by_id', deck_id=deck_id))

    return render_template('create_card.html', deck=deck)


@app.route('/cards/<int:card_id>', methods=['GET'])
def card_get_by_id(card_id):
    """
    Retrieves a flashcard by its ID and returns the Card object.
    """
    card = Card.query.get(card_id)  # Fetch the card from the database using the card ID
    if card:
        return render_template('card_details.html', card=card)
    flash('Card not found!', 'danger')
    return redirect(url_for('list_cards'))  # Redirect to list all cards if not found


@app.route('/cards/<string:sub_word>', methods=['GET'])
def card_filter(sub_word):
    """
    Retrieves all flashcards containing a substring in word, translation, or tip fields.
    """
    if sub_word:
        cards = Card.query.filter(
            (Card.word.ilike(f"%{sub_word}%")) |
            (Card.translation.ilike(f"%{sub_word}%")) |
            (Card.tip.ilike(f"%{sub_word}%"))
        ).all()

        # Return only the filtered table HTML
        return render_template('filtered_cards_partial.html',
                               cards=cards)  # Assuming this template renders only <tbody>

    flash('Please enter a search query.', 'info')
    return redirect(url_for('list_cards'))


@app.route('/cards/edit/<int:card_id>', methods=['GET', 'POST'])
def edit_card(card_id):
    card = Card.query.get_or_404(card_id)

    if request.method == 'POST':
        # Get the updated values from the form
        word = request.form.get('word')
        translation = request.form.get('translation')
        tip = request.form.get('tip')

        # Update the card
        card.word = word
        card.translation = translation
        card.tip = tip

        # Commit the changes to the database
        db.session.commit()

        flash('Card updated successfully!', 'success')
        return redirect(url_for('list_cards'))  # Redirect to the list of cards after updating

    return render_template('edit_card.html', card=card)


@app.route('/decks/<int:deck_id>/update', methods=['GET', 'POST'])
def update_deck(deck_id):
    deck = Deck.query.get(deck_id)

    if not deck:
        flash('Deck not found!', 'danger')
        return redirect(url_for('list_decks'))  # Redirect to the list of decks if not found

    if request.method == 'POST':
        deck_name = request.form['name']  # Get the updated deck name from the form
        deck.name = deck_name  # Update the deck's name

        # Handle cards data
        cards_data = request.form.get('cards')
        if cards_data:
            try:
                cards = json.loads(cards_data)  # Convert JSON to list of card objects
                existing_cards = {card.word: card for card in deck.cards}

                for card_data in cards:
                    word = card_data.get('word')
                    if word in existing_cards:
                        # Update existing card
                        existing_card = existing_cards[word]
                        existing_card.translation = card_data.get('translation', existing_card.translation)
                        existing_card.tip = card_data.get('tip', existing_card.tip)
                    else:
                        # Add new card
                        new_card = Card(
                            word=word,
                            translation=card_data.get('translation', ''),
                            tip=card_data.get('tip', ''),
                            deck_id=deck_id
                        )
                        db.session.add(new_card)

                db.session.commit()
                flash('Deck updated successfully!', 'success')
            except json.JSONDecodeError:
                flash('Invalid card data format!', 'danger')

        return redirect(url_for('list_decks'))

    # If method is GET, render the update deck form
    return render_template('update_deck.html', deck=deck)


@app.route('/cards/<int:card_id>/delete', methods=['POST'])
def card_delete_by_id(card_id):
    """
    Deletes a flashcard by its ID and returns a Boolean value indicating success or failure.
    """
    card = Card.query.get(card_id)

    if card:
        db.session.delete(card)
        db.session.commit()
        flash('Card deleted successfully!', 'success')
        return redirect(url_for('list_cards'))  # Redirect to the list of cards after deletion

    flash('Card not found!', 'danger')
    return redirect(url_for('list_cards'))  # Redirect in case of failure


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)

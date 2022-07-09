import os
import json
import asyncio
from db import UsersList

from web3 import Web3
from web3 import HTTPProvider

from aiogram import Bot, Dispatcher, executor, types
from aiogram.dispatcher import filters
from dotenv import load_dotenv

load_dotenv()

bot = Bot(token=os.getenv('TOKEN'))
dp = Dispatcher(bot)
web3 = Web3(HTTPProvider(os.getenv('WEB3PROVIDER')))

buttons = types.ReplyKeyboardMarkup(resize_keyboard=True)
buttons.add(types.KeyboardButton('Set account'))
buttons.add(types.KeyboardButton('Set language'))

with open('contract.json', 'r', encoding='utf-8') as out:
    contract = json.load(out)
    contract = web3.eth.contract(address=contract['address'], abi=contract['abi'])

with open('languages.json', 'r', encoding='utf-8') as out:
    languages = json.load(out)

with open('signed_users.json', 'r', encoding='utf-8') as out:
    signed_users = UsersList(json.load(out))

async def log_loop(event_filters, poll_interval):
    while True:
        for event_filter in event_filters:
            for pair_created in event_filter.get_new_entries():
                await handle_event(pair_created)
        
        await asyncio.sleep(poll_interval)

async def handle_event(event):
    event_args = json.loads(Web3.toJSON(event))

    if event_args['event'] == 'NewGame':
        event_args = event_args['args']
        message = f"New game!\nPay: {event_args['amountToPay']}"

        for user in signed_users:
            await bot.send_message(user['id'], message)
    
    elif event_args['event'] == 'GamePaymentEvent':
        event_args = event_args['args']
        message = f"You get {Web3.fromWei(event_args['amountToPay'] * 0.74, 'ether')}!" \
            if event_args['success'] else "You can not receive payments!"

        user = signed_users.find_user_by_address(event_args['account'])

        if user:
            await bot.send_message(user['id'], message)
    
    elif event_args['event'] == 'ReferalPaymentEvent':
        event_args = event_args['args']
        user = signed_users.find_user_by_refid(event_args['to'])
        message = f"You get {Web3.fromWei(event_args['amount'], 'ether')} referal payment from {event_args['from']}"

        if user:
            await bot.send_message(user['id'], message)

@dp.message_handler(commands="start")
async def on_start_message_callback(message: types.Message):
    print(message)
    find_user = signed_users.find_user_by_id(message.from_user.id)

    if not find_user:
        user = signed_users.get_default_user(message.from_user.id)
        signed_users.append(user)
    
    else:
        user = find_user
    
    await message.reply(languages[user['language']]["greating"], reply_markup=buttons)

@dp.message_handler(filters.Text(contains=['Set account'], ignore_case=True))
async def on_set_account_message_callback(message: types.Message):
    user = signed_users.find_user_by_id(message.from_user.id)
    await message.reply(languages[user['language']]["set_account"])

@dp.message_handler(filters.Text(contains=['Set language'], ignore_case=True))
async def on_set_language_message_callback(message: types.Message):
    user = signed_users.find_user_by_id(message.from_user.id)

    languages_buttons = types.InlineKeyboardMarkup()\
        .add(types.InlineKeyboardButton('English', callback_data = "language en"))\
        .add(types.InlineKeyboardButton('Ukrainian', callback_data = "language ua"))\

    await bot.send_message(
        message.from_user.id,
        languages[user['language']]["select_language"],
        reply_markup = languages_buttons
    )

@dp.callback_query_handler(lambda callback: callback.data.startswith('language'))
async def set_user_language_callback_button(callback_query: types.CallbackQuery):
    language = callback_query.data.split()[-1]
    signed_users.edit_user(callback_query.from_user.id, language=language)

    await bot.send_message(callback_query.from_user.id, languages[language]["successfully_set_language"])

@dp.message_handler(filters.Regexp(r'^[0-9]+$'))
async def on_set_account_refid_callback(message: types.Message):
    user = signed_users.edit_user(message.from_user.id, ref_id=message.text)
    address = contract.functions.usersId(int(message.text)).call()
    user = signed_users.edit_user(message.from_user.id, address=address)

    await message.reply(languages[user['language']]["successfully_set_account"])

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    event_filters = [
        contract.events.NewGame.createFilter(fromBlock='latest'),
        contract.events.GamePaymentEvent.createFilter(fromBlock='latest'),
        contract.events.ReferalPaymentEvent.createFilter(fromBlock='latest')
    ]

    loop.create_task(log_loop(event_filters, 1))
    executor.start_polling(dp, skip_updates=True)

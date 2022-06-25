import os
import json
import asyncio
from pyrsistent import s

from web3 import Web3
from web3 import HTTPProvider

from aiogram import Bot, Dispatcher, executor, types
from dotenv import load_dotenv

class UsersList(list):
    def append(self, __object) -> None:
        with open('signed_users.json', 'w', encoding='utf-8') as out:
            super().append(__object)
            json.dump(self, out, indent=4)

load_dotenv()

bot = Bot(token=os.getenv('TOKEN'))
dp = Dispatcher(bot)
web3 = Web3(HTTPProvider(os.getenv('WEB3PROVIDER')))

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
        event_args = event_args['args']['game']
        message = f"New game!\nCircle: {event_args[0]}\nPay: {event_args[1]} and get {event_args[2]}"
    
    elif event_args['event'] == 'WinnerPayment':
        event_args = event_args['args']
        message = f"New winner!\n{event_args['winner']} get {event_args['game'][-1]}"

    await bot.send_message('1052311571', message)

@dp.message_handler(commands="start")
async def cmd_test1(message: types.Message):
    filter_users = [user for user in signed_users if user['id'] == message.from_id]

    if not filter_users:
        user = {"id": message.from_id, "language": "en"}
        signed_users.append(user)
    
    else:
        user = filter_users[0]

    await message.reply(languages[user['language']]["greating"])

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    event_filters = [
        contract.events.NewGame.createFilter(fromBlock='latest'),
        contract.events.WinnerPayment.createFilter(fromBlock='latest')
    ]

    loop.create_task(log_loop(event_filters, 2))
    executor.start_polling(dp, skip_updates=True)

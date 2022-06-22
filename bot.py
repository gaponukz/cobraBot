import os
import json
import asyncio

from web3 import Web3
from web3 import HTTPProvider

from aiogram import Bot
from dotenv import load_dotenv

load_dotenv()

bot = Bot(token=os.getenv('TOKEN'))
web3 = Web3(HTTPProvider(os.getenv('WEB3PROVIDER')))

with open('contract.json', 'r', encoding='utf-8') as out:
    contract = json.load(out)
    contract = web3.eth.contract(address=contract['address'], abi=contract['abi'])

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

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    event_filters = [
        contract.events.NewGame.createFilter(fromBlock='latest'),
        contract.events.WinnerPayment.createFilter(fromBlock='latest')
    ]

    loop.run_until_complete(asyncio.gather(log_loop(event_filters, 2)))

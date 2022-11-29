#!/usr/bin/env python
import argparse
import requests  # as aiohttp.request is leaking
from aiohttp import web
import logging
import sys
import os

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def parse_args():
    parser = argparse.ArgumentParser(prog='beats-exporter', description='Prometheus exporter for Elastic Beats')
    parser.add_argument('-a', '--addresses', action='store', type=str, default=os.environ.get('ADDRESSES_TO_SCRAPE'), help='Addresses to scrape (host:port comma separated)')
    parser.add_argument('-f', '--filter', action='append', type=str, default=[], help='Filter metrics (default: disabled)')
    parser.add_argument('-l', '--log', choices=['info', 'warn', 'error'], default='info', help='Logging level (default: info)')
    parser.add_argument('-m','--metrics-port', action='store', type=int, default=8080, help='Expose metrics on port (default: 8080)')
    args = parser.parse_args()
    logger.setLevel(getattr(logging, args.log.upper()))
    return args


async def handler(request):
    text = []
    for address in set(request.app['args'].addresses.split(",")):
        beat = request.app['beats'][address.replace(":","->")]['name']
        try:
            text += [f'{beat}_info{{version="{request.app["beats"][address.replace(":","->")]["version"]}"}} 1']
            text += get_metric(data=requests.get(f'http://{address}/stats').json(), prefix=beat)
        except Exception as e:
            logger.error(f"Error reading {beat} at address {address}\n{e}")
            return web.Response(status=500, text=str(e))

    if request.app['args'].filter:
        tmp = text
        text = []
        for line in tmp:
            for sub in set(request.app['args'].filter):
                if sub in line:
                    text.append(line)
                    break

    return web.Response(text='\n'.join(text))


def get_info(args):
    beats = {}
    for address in set(args.addresses.split(",")):
        try:
            beats[address.replace(":","->")] = requests.get(f'http://{address}').json()
        except Exception as e:
            logger.error(f"Error connecting Beat at address {address}\n{e}")
            sys.exit(1)
    return beats


def get_metric(data, prefix):
    result = []
    for k, v in data.items():
        if type(v) == dict:
            if not [x for x in v if type(v[x]) in [dict, str]] and len(v) > 1:
                result += [f'{prefix}{{{k}="{x}"}} {v[x]}' for x in v]
            else:
                result += get_metric(v, f'{prefix}_{k}')
        elif type(v) == str:
            result += [f'{prefix}{{{k}="{v}"}} 1']
        else:
            result += [f'{prefix}_{k} {v}']
    return result


if __name__ == "__main__":
    args = parse_args()

    app = web.Application()
    app.router.add_get("/metrics", handler)
    app['args'] = args
    app['beats'] = get_info(args)
    web.run_app(app, port=args.metrics_port, access_log=logger)

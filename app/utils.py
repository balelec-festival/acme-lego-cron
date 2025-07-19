import os
import subprocess
import logging
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Command:
    name: str
    command: list[str]

def run_command_raw(command: Command) -> (str, int):
    """
    Executes a command from a list of arguments
    Returns: command output and return code.
    """

    try:
        result = subprocess.run(
            command.command,
            shell=False,          # Explicitly set to False for security
            text=True,            # Decode output as text (strings)
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
        )

        return result.stdout, result.returncode

    except FileNotFoundError:
        return f"Error: Executable '{command.command[0]}' not found.\n", 1

def run_command_abort_on_failure(command: Command):
    output, return_code = run_command_raw(command)

    if return_code == 0:
        logging.info(f"{command.name} command successful, output is:\n"
                     f"{output}")
    else:
        logging.error(f"{command.name} command failed, output is:\n"
                      f"{output}")
        exit(1)

def env_set_if_unset(key:str, val:str) -> str:
    if key not in os.environ:
        os.environ[key] = val
    return os.environ[key]

def get_lego_env_params():
    params = {}

    params['LEGO_VOLUME'] = os.environ.get('LEGO_VOLUME', default='/lego_data')
    if not Path(params['LEGO_VOLUME']).is_dir():
        logging.error("LEGO_VOLUME env var not provided or not a directory")
        exit(1)

    params['CERTS_VOLUME'] = os.environ.get('CERTS_VOLUME')
    if not Path(params['CERTS_VOLUME']).is_dir():
        logging.error("CERTS_VOLUME env var not provided or not a directory")
        exit(1)

    params['KEY_TYPE'] = os.environ.get('KEY_TYPE', default='ec384')

    params['STAGING'] = os.environ.get('STAGING', default='0')
    params['api_endpoint'] = 'https://acme-v02.api.letsencrypt.org/directory'
    if params['STAGING'] == '1':
        params['api_endpoint'] = 'https://acme-staging-v02.api.letsencrypt.org/directory'

    DOMAIN_LEGO_ARGS = []
    if 'DOMAINS' in os.environ and len(os.environ['DOMAINS']) != 0:
        for x in os.environ['DOMAINS'].split(';'):
            if x:  # Nice if you forget a trailing ;
                DOMAIN_LEGO_ARGS.extend(('--domains', x))
    else:
        logging.error("DOMAINS env var not provided or empty.")
        exit(1)
    params['DOMAIN_LEGO_ARGS'] = DOMAIN_LEGO_ARGS

    if not ('EMAIL_ADDRESS' in os.environ and len(os.environ['EMAIL_ADDRESS']) != 0):
        logging.error("EMAIL_ADDRESS env var not provided or empty.")
        exit(1)
    params['EMAIL_ADDRESS'] = os.environ['EMAIL_ADDRESS']

    if not ('PROVIDER' in os.environ and len(os.environ['PROVIDER']) != 0):
        logging.error("PROVIDER env var not provided or empty.")
        exit(1)
    params['PROVIDER'] = os.environ['PROVIDER']

    params['DNS_TIMEOUT'] = os.environ.get('DNS_TIMEOUT', default='10')


    return params

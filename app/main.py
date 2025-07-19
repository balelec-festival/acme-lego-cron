import json
import sys
import logging
from pathlib import Path

from app.utils import get_lego_env_params, env_set_if_unset, Command, run_command_abort_on_failure


logging.basicConfig(
    format='%(asctime)s - %(levelname)s - %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S'
)


# Used in post renewal script, use root (uid=0) as default value
CERT_OWNERS = env_set_if_unset('CERT_OWNERS', '0')
env_set_if_unset('CERTS_VOLUME', '/certs')

lego_params = get_lego_env_params()
current_env_vars = {
    'lego_params': lego_params,
    'cert_owners': CERT_OWNERS
}

env_file_path = Path(lego_params['LEGO_VOLUME']) / "environ_snapshot.json"

previous_env_vars = {}
try:
    with open(env_file_path, 'r') as f:
        previous_env_vars = json.load(f)
except FileNotFoundError:
    logging.info("No previous environment variable snapshot found. Creating one now.")
except json.JSONDecodeError:
    logging.warning("Could not decode the existing snapshot file. A new one will be created.")

lego_dir = Path(lego_params['LEGO_VOLUME']) / "lego"
lego_dir.mkdir(exist_ok=True)

lego_command = [
        "./lego", "--server", lego_params['api_endpoint'], "--path", lego_dir, "--accept-tos",
        f"--key-type={lego_params['KEY_TYPE']}", *lego_params['DOMAIN_LEGO_ARGS'], "--email", lego_params['EMAIL_ADDRESS'],
        "--pem", "--dns", lego_params['PROVIDER'], "--dns-timeout", lego_params['DNS_TIMEOUT']
]

post_renewal_hook_path = "./app/post-renewal-hook.sh"

# If these parameters change, lego needs to run again
if current_env_vars['lego_params'] != previous_env_vars.get('lego_params', None):
    logging.info("Changes in env variables, running lego in 'run' mode")

    run_command_abort_on_failure(
        Command("Run LEGO", [*lego_command, "run", f"--run-hook={post_renewal_hook_path}"])
    )

else:
    logging.info("No changes in env variables, running lego in 'renew' mode")

    run_command_abort_on_failure(
        Command("Renew LEGO", [*lego_command, "renew", f"--renew-hook={post_renewal_hook_path}"])
    )

    # If the certificate needed to be renewed just when the cert_owners variable changed,
    # the post-renewal-hook will run twice. Services will restart twice but this should not be a problem
    if current_env_vars['cert_owners'] != previous_env_vars['cert_owners']:
        logging.info("CERT_OWNERS env variable changed, running post-renewal-hook.sh")

        run_command_abort_on_failure(
            Command("Run post-renewal-hook.sh", [post_renewal_hook_path])
        )


logging.info(f"Saving environment variable snapshot to: {env_file_path}")
try:
    with open(env_file_path, 'w') as f:
        json.dump(current_env_vars, f, indent=4, sort_keys=True)
except IOError as e:
    logging.error(f"Failed to write to file {env_file_path}: {e}")
    sys.exit(1)

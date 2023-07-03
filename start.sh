# Instructions for starting runpod container here
echo "Container is running"

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au /venv/ /workspace/venv/
rm -rf /venv

# Sync Web UI to workspace to support Network volumes
echo "Syncing Bark Web UI to workspace, please wait..."
rsync -au /bark/ /workspace/bark/
rm -rf /bark

# Fix the venvs to make them work from /workspace
echo "Fixing Bark Web UI venv..."
/fix_venv.sh /venv /workspace/venv

if [[ ${PUBLIC_KEY} ]]
then
    echo "Installing SSH public key"
    mkdir -p ~/.ssh
    echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys
    chmod 700 -R ~/.ssh
    service ssh start
    echo "SSH Service Started"
fi

if [[ ${JUPYTER_PASSWORD} ]]
then
    echo "Starting Jupyter lab"
    ln -sf /examples /workspace
    ln -sf /root/welcome.ipynb /workspace

    source /workspace/venv/bin/activate
    cd /
    nohup jupyter lab --allow-root \
        --no-browser \
        --port=8888 \
        --ip=* \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --ServerApp.token=${JUPYTER_PASSWORD} \
        --ServerApp.allow_origin=* \
        --ServerApp.preferred_dir=/workspace &
    echo "Jupyter Lab Started"
    deactivate
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/bark"
    echo "   deactivate && source /workspace/venv/bin/activate"
    echo "   ./python3 bark_webui.py --listen 0.0.0.0 --server_port 7860"
else
    mkdir -p /workspace/logs
    echo "Starting bark"
    source /workspace/venv/bin/activate
    cd /workspace/bark && nohup python3 bark_webui.py --listen 0.0.0.0 --server_port 7860 > /workspace/logs/bark.log 2>&1 &
    echo "bark started"
    echo "Log file: /workspace/logs/bark.log"
    deactivate
fi

echo "All services have been started"

sleep infinity

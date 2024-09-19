#!/bin/sh
#SBATCH --time=08:00:00
#SBATCH -p gpu
#SBATCH --signal=USR2
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --gres=gpu:2g.10gb:1
#SBATCH --qos=custom
#SBATCH --output=job.jupyter.%j

workdir=$(python3 -c 'import tempfile; print(tempfile.mkdtemp())')
echo ${workdir}

export SINGULARITY_BIND="${workdir}, $PWD"

XDG_RUNTIME_DIR=""
node=$(hostname -s)
user=$(whoami)
cluster=$(hostname)

readonly PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

cat 1>&2 <<END

1. SSH tunnel from you workstation using the following command:

	- MacOS or linux terminal

		ssh -N -L ${PORT}:localhost:${PORT} $user@$(hostname -I | cut -d ' ' -f 1) -p 22022

	- Windows MobaXterm info
		Forwarded port : same as remote port
		Remote Server  : ${node}
		Remote Port    : ${PORT}
		SSH Server     : $(hostname -I | cut -d ' ' -f 1)
		SSH Login      : $user
		SSH port       : 22022

2. cat the output file to get URP at the very bottom of the file and copy it.

	"http:127.0.0.1:${PORT}/?token=..."

3. Adter SSH tunnel done, Place the URL in with token to the browser

When done using Jupyter Notebook, terminate the job by:

1. Exit the Jupyter Notebook Sessing
2. Issue the following command on the login note:

	scanel -f ${SLURM_JOB_ID}

END

singularity exec --nv /data/home/$user/ubuntu_custom_v.1.5.sif \        #you can edit version ubuntu_custom
	jupyter-notebook --no-browser --port=${PORT} --ip=0.0.0.0


print 'jupyter notebook exited' 1>&2

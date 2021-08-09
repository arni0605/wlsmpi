# @ Vasudeva Manikandan/Arnab Ghosh
# Purpose: Set Environment Vailables
# Customize Display Name and Description

export config_file="C:/Users/ARNAGHOS/.oci/config"

export display_name="Weblogic MPI through OCI CLI"

export stack_description="WLS automated provisioning for OCI"

export config_source="p2p-wls-mpi-tf.zip"

#export PLAN_JOB_LOGS_FILE=Plan_Job_Logs.txt

export JOB_TF_STATE=Job_Tf_State.txt

#export APPLY_JOB_LOGS_FILE=Apply_Job_Logs.txt

# Remove any JSON and TXT Files
rm -rf *.json
rm -rf *.txt
rm -rf *.log_*
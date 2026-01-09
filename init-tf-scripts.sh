# in the file terraform.tf, replace '###GCS_PREFIX###' 
# with "${ACCOUNT_NAME} + / +  ${PROJECT_NAME} + / + XXX"
sed -i "s|###GCS_PREFIX###|${ACCOUNT_NAME}/${PROJECT_NAME}|g" terraform.tf

# init terraform.tfvars
cat <<EOF > values.tfvars
# Terraform variables for Mink Bootstrap
account_name = "${ACCOUNT_NAME}"
project_name = "${PROJECT_NAME}"
EOF

# python-dynamodb-table-write

```bash
export AWS_VAULT_FILE_PASSPHRASE="$(cat /root/.awsvaultk)"
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/01 init
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/01 apply --auto-approve
```

```bash
source ./terraform/01/terraform.tmp
```

```bash
export TABLE_NAME=dynamodb-table-write-0g55ncwb
```

```bash
export TABLE_ITEM='{"source": "example_source", "timestamp": "2024-07-22T19:29:09", "region": "ap-southeast-1"}'
```

```bash
python ./write_dynamodb_table_item/lambda_function.py
```

```bash
mkdir -p ./terraform/02/external
```

```bash
zip -r -j ./terraform/02/external/write_dynamodb_table_item.zip ./write_dynamodb_table_item
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/02 init
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/02 apply --auto-approve
```

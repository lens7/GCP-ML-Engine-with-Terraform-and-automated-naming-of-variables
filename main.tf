provider "google" {
 project     = "${var.project-name}"
 region      = "${var.REGION}"
}

locals {
  timestamp = "${timestamp()}"
  timestamp_sanitized = "${replace("${local.timestamp}", "/[-| |T|Z|:]/", "")}"
  fdate = "${formatdate("HH:mmaa", "${timestamp()}")}"
  fdate_sanitized = "${replace("${local.fdate}", "/[:|am]/", "")}"
}

resource "null_resource" "ex1" {
  provisioner "local-exec" {
    command    = <<EOF
wget https://github.com/GoogleCloudPlatform/cloudml-samples/archive/master.zip
unzip master.zip
cd cloudml-samples-master/census/estimator
gsutil cp -r gs://cloud-samples-data/ai-platform/census/data/ gs://${var.BUCKET_NAME1}/ 
TRAIN_DATA=gs://"${var.BUCKET_NAME1}"/data/adult.data.csv
EVAL_DATA=gs://"${var.BUCKET_NAME1}"/data/adult.test.csv
pip install --user tensorflow==1.14.*
MODEL_DIR=output
rm -rf $MODEL_DIR/*
gcloud ai-platform local train --module-name trainer.task --package-path trainer/ --job-dir output/ -- --train-files $TRAIN_DATA --eval-files $EVAL_DATA --train-steps 100 --eval-steps 100
TRAIN_DATA=gs://"${var.BUCKET_NAME1}"/data/adult.data.csv
EVAL_DATA=gs://"${var.BUCKET_NAME1}"/data/adult.test.csv
gsutil cp ../test.json gs://${var.BUCKET_NAME1}/data/test.json
TEST_JSON=gs://"${var.BUCKET_NAME1}"/data/test.json
OUTPUT_PATH=gs://"${var.BUCKET_NAME1}"/"${var.JOB_NAME}${local.fdate_sanitized}"
gcloud ai-platform jobs submit training "${var.JOB_NAME}${local.fdate_sanitized}" --job-dir $OUTPUT_PATH --runtime-version 1.14 --module-name trainer.task --package-path trainer/ --region "${var.REGION}" -- --train-files $TRAIN_DATA --eval-fi$
gcloud ai-platform jobs stream-logs "${var.JOB_NAME}${local.fdate_sanitized}"
gcloud ai-platform models create "${var.MODEL_NAME}${local.fdate_sanitized}" --regions "${var.REGION}"
MODEL_BINARIES=$(gsutil ls gs://${var.BUCKET_NAME1}/${var.JOB_NAME}${local.fdate_sanitized}/export/census/ |tail -1)
gcloud ai-platform versions create "${var.VER}${local.fdate_sanitized}" --model "${var.MODEL_NAME}${local.fdate_sanitized}" --origin $MODEL_BINARIES --runtime-version=1.15
gcloud ai-platform models list
gcloud ai-platform predict --model "${var.MODEL_NAME}${local.fdate_sanitized}" --version "${var.VER}${local.fdate_sanitized}" --json-instances ../test.json
OUTPUT_PATH=gs://"${var.BUCKET_NAME1}"/"${var.JOB_NAME1}${local.fdate_sanitized}"
gcloud ai-platform jobs submit prediction "${var.JOB_NAME1}${local.fdate_sanitized}" --model "${var.MODEL_NAME}${local.fdate_sanitized}" --version "${var.VER}${local.fdate_sanitized}" --data-format text --region "${var.REGION}" --input-paths $TEST_JSON --output-path $OUTPUT_PATH/predictions
gcloud ai-platform jobs describe "${var.JOB_NAME1}${local.fdate_sanitized}"
gcloud ai-platform jobs stream-logs "${var.JOB_NAME1}${local.fdate_sanitized}"
gsutil cat $OUTPUT_PATH/predictions/prediction.results-00000-of-00001
EOF
  }
}


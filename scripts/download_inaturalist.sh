#!/bin/bash

set -e

PROCESSORS=8

# Define the expected hash values
TRAIN_VAL_HASH="c60a6e2962c9b8ccbd458d12c8582644"
TEST_HASH="6966703cc589a877689dc8993bb3e55e"

# Download the iNaturalist19 dataset in parallel
echo "Downloading the iNaturalist19 dataset..."
curl -sO 'https://ml-inat-competition-datasets.s3.amazonaws.com/2019/train_val2019.tar.gz' &
curl -sO 'https://ml-inat-competition-datasets.s3.amazonaws.com/2019/test2019.tar.gz' &
wait

# Check the hash values of the downloaded files
ACTUAL_TRAIN_VAL_HASH=$(md5sum train_val2019.tar.gz | awk '{print $1}')
ACTUAL_TEST_HASH=$(md5sum test2019.tar.gz | awk '{print $1}')

if [ "$TRAIN_VAL_HASH" != "$ACTUAL_TRAIN_VAL_HASH" ]; then
  echo "Hash check failed for train_val2019.tar.gz."
  exit 1
fi

if [ "$TEST_HASH" != "$ACTUAL_TEST_HASH" ]; then
  echo "Hash check failed for test2019.tar.gz."
  exit 1
fi

# Extract the dataset in parallel
echo "Extracting the iNaturalist19 dataset... (~20 min)"
pigz -dc -p $PROCESSORS test2019.tar.gz | tar xf - &
pigz -dc -p $PROCESSORS train_val2019.tar.gz | tar xf - &
wait
rm test2019.tar.gz train_val2019.tar.gz

# Move all the images into a single directory tmp (this will speed up future operations)
echo "Moving all images into a single directory..."
mkdir tmp
find train_val2019 -name "*.jpg" -type f -print0 | xargs -0 mv -t tmp/
find test2019 -name "*.jpg" -type f -print0 | xargs -0 mv -t tmp/
rm -rf train_val2019 test2019

# Follow the same recepie provided in making-better-mistakes (resize by stretching)
echo "Resizing all images to 224x224...(~60 min)"
find tmp -name "*.jpg" -print0 | xargs -0 -P $PROCESSORS -I{} mogrify -resize 224x224! {}

# Download the iNaturalist19 splits provided by making-better-mistakes
echo "Downloading the iNaturalist19 splits..."
curl -sO 'https://raw.githubusercontent.com/fiveai/making-better-mistakes/master/dataset_splits/splits_inat19.zip'
unzip -qq splits_inat19.zip

# Organize the images according to splits_inat19
echo "Organizing the images according to iNaturalist19 splits..."
cd tmp
for file in ../splits_inat19/*/*.txt
do
  dir=$(dirname "$file")
  dir=${dir#../splits_inat19/}
  name=$(basename "$file" .txt)
  images=$(tr '\n' ' ' < "$file")
  mkdir -p "../iNaturalist19/$dir/$name"
  mv $images "../iNaturalist19/$dir/$name/"
done
cd ..
rm -rf tmp splits_inat19 splits_inat19.zip

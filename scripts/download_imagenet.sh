#!/bin/bash

set -e

PROCESSORS=8

# Download the ImageNet dataset
echo "Downloading the ImageNet dataset..."
curl -O 'https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_train.tar'
curl -O 'https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar'

# Extract the dataset in parallel
echo "Extracting the ImageNet dataset..."
mkdir ILSVRC2012_img_train
tar -xf ILSVRC2012_img_train.tar -C ILSVRC2012_img_train
rm ILSVRC2012_img_train.tar
find ILSVRC2012_img_train -name "*.tar" -print0 | xargs -0 -P $PROCESSORS -I {} tar -xf {} -C ILSVRC2012_img_train
rm ILSVRC2012_img_train/*.tar
mkdir ILSVRC2012_img_val
tar -xf ILSVRC2012_img_val.tar -C ILSVRC2012_img_val
rm ILSVRC2012_img_val.tar

# Move all the images into a single directory tmp (this will speed up future operations)
echo "Moving all images into a single directory..."
mkdir tmp
find ILSVRC2012_img_train -name "*.JPEG" -type f -print0 | xargs -0 mv -t tmp/
find ILSVRC2012_img_val -name "*.JPEG" -type f -print0 | xargs -0 mv -t tmp/
rm -rf ILSVRC2012_img_train ILSVRC2012_img_val

# Follow the same recepie provided in making-better-mistakes (resize by stretching)
echo "Resizing all images to 224x224..."
find tmp -name "*.JPEG" -print0 | xargs -0 -P $PROCESSORS -I{} mogrify -resize 224x224! {}

# Download the tieredImageNet-H splits provided by making-better-mistakes
echo "Downloading the tieredImageNet-H splits..."
curl -sO 'https://raw.githubusercontent.com/fiveai/making-better-mistakes/master/dataset_splits/splits_tiered.zip'
unzip -qq splits_tiered.zip

# Organize the images according to splits_tieredImageNet-H
echo "Organizing the images according to tieredImageNet-H splits..."
cd tmp
for file in ../splits_tieredImageNet-H/*/*.txt
do
  dir=$(dirname "$file")
  dir=${dir#../splits_tieredImageNet-H/}
  name=$(basename "$file" .txt)
  images=$(tr '\n' ' ' < "$file")
  mkdir -p "../tieredImageNet-H/$dir/$name"
  mv $images "../tieredImageNet-H/$dir/$name/"
done
cd ..
rm -rf tmp splits_tieredImageNet-H/ splits_tiered.zip

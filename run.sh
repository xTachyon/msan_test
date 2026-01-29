set -ex

if [ -z "$1" ]; then
    target_dir="$HOME/llvm_msan"
else
    target_dir="$1"
fi

docker build . --progress plain --output=$target_dir

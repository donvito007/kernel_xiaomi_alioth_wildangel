# downloading toolchain
wget -O 64.zip https://github.com/mvaisakh/gcc-arm64/archive/85b79055a926ffa45ed7ce0005731d7bda4db137.zip;unzip 64.zip;mv gcc-arm64-85b79055a926ffa45ed7ce0005731d7bda4db137 gcc64
wget -O 32.zip https://github.com/mvaisakh/gcc-arm/archive/b9cada9f629b7b3f72b201c77d93042695de33fc.zip;unzip 32.zip;mv gcc-arm-b9cada9f629b7b3f72b201c77d93042695de33fc gcc32
git clone --depth=1 https://github.com/farizmaul/AnyKernel3.git

# setup kernel configuration
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
START=$(date +"%s")
BRANCH=$(git rev-parse --abbrev-ref HEAD)
VERSION=MIUI
TANGGAL=$(TZ=Asia/Jakarta date "+%Y%m%d-%H%M")

# toolchain directory
TC_DIR=${PWD}
GCC64_DIR="${TC_DIR}/gcc64"
GCC32_DIR="${TC_DIR}/gcc32"
KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-elf-gcc --version | head -n 1)

# Set Kernel Version
KERNELVER=$(make kernelversion)

# Include argument
ARGS="ARCH=arm64 \
	O=out \
	LOCALVERSION=-${TANGGAL} \
	AR=llvm-ar \
	OBJDUMP=llvm-objdump \
	STRIP=llvm-strip \
	CROSS_COMPILE_ARM32=arm-eabi- \
	CROSS_COMPILE=aarch64-elf- \
	LD=ld.lld"

# Build Kernel
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_HOST="android"
export KBUILD_BUILD_USER="ricoayuba"
export KBUILD_COMPILER_STRING

#main group
export chat_id="-1001726996867"
#channel
export chat_id2="-1001608547174"

# set defoconfig
export DEF="vendor/alioth_defconfig"
export PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH

# Post to CI channel
curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Buckle up bois HyperX kernel build has started" -d chat_id=${chat_id} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Kernel Version : <code>${KERNELVER}</code>
Compiler Used : <code>${KBUILD_COMPILER_STRING}</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
Starting..." -d chat_id=${chat_id} -d parse_mode=HTML

# make defconfig
    make -j$(nproc --all) ${ARGS} ${DEF}

# Make olddefconfig
cd out || exit
make -j$(nproc --all) ${ARGS} olddefconfig
cd ../ || exit

# compiling
    make -j$(nproc --all) ${ARGS} 2>&1 | tee build.log

END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/Image ]
	then
	curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="<i>Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</i>" -d chat_id=${chat_id} -d parse_mode=HTML
        cp ${IMAGE} $(pwd)/AnyKernel3
        cp ${DTBO} $(pwd)/AnyKernel3
        cd AnyKernel3
        zip -r9 HyperX-MIUI-${TANGGAL}.zip * --exclude *.jar

        curl -F chat_id="${chat_id}"  \
                    -F caption="sha1sum: $(sha1sum Hyp*.zip | awk '{ print $1 }')" \
                    -F document=@"$(pwd)/HyperX-MIUI-${TANGGAL}.zip" \
                    https://api.telegram.org/bot${TOKEN}/sendDocument

        curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="hi guys, the latest update is available on @HyperX_Archive !" -d chat_id=${chat_id2} -d parse_mode=HTML

cd ..
else
        curl -F chat_id="${chat_id}"  \
                    -F caption="Build ended with an error !!" \
                    -F document=@"build.log" \
                    https://api.telegram.org/bot${TOKEN}/sendDocument

fi

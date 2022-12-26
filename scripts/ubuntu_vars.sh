# Assumes $UBUNTU_KERNEL_VERSION to be set
# e.g. UBUNTU_KERNEL_VERSION=ubuntu/focal/Ubuntu-5.4.0-113.127

DISTRO=$(echo "${UBUNTU_KERNEL_VERSION}" | cut -d'/' -f 1)
DISTRO_RELEASE=$(echo "${UBUNTU_KERNEL_VERSION}" | cut -d'/' -f 2)
KERNEL_VERSION_RAW=$(echo "${UBUNTU_KERNEL_VERSION}" | cut -d'/' -f 3)

HWE_TAG=$(echo "${UBUNTU_KERNEL_VERSION}"|grep -Po "Ubuntu-hwe-[^-]+" || echo "")
if [ -z "$HWE_TAG" ]
then
    KERNEL_TAG=$(echo "${UBUNTU_KERNEL_VERSION}"|grep -Po "(?<=$DISTRO_RELEASE/)[_a-zA-Z0-9-\.]+(?=$)")
    HWE_VERSION=""
else
    KERNEL_TAG=$(echo "${UBUNTU_KERNEL_VERSION}"|grep -Po "(?<=$DISTRO_RELEASE/)$HWE_TAG-[_a-zA-Z0-9-\.]+(?=$)")
    HWE_VERSION=$(echo $HWE_TAG|grep -Po "[0-9\.]+")
fi
KERNEL_FLAVOR="-generic"
KERNEL_VERSION=$(echo "${UBUNTU_KERNEL_VERSION}"|grep -Po "(?<=$HWE_VERSION\-)[0-9\.-]+(?=\.[0-9]+)")
KERNEL_VERSION_MAJOR=$(echo "${KERNEL_VERSION}"|grep -Po "^([0-9]+\.[0-9]+)")
KERNEL_VERSION_FULL=$(echo "${UBUNTU_KERNEL_VERSION}"|grep -Po "(?<=$HWE_VERSION\-)[0-9\.-]+\.[0-9]+")

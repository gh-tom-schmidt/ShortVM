#!/bin/bash

# ------------------------------------- functions ------------------------------------

# Check and create a folder if it doesn't exist
check_and_create_folders() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# Check if a file exists in source_path
present_source() {
    if [ -f "${source_path}/$1" ]; then 
        return 0 # true
    else 
        return 1 # false
    fi
}

# Check if a file exists in vms_path
present_vms() {
    if [ -f "${vms_path}/$1.qcow2" ]; then 
        return 0 # true
    else 
        return 1 # false
    fi
}

# Input: 1 - new_name, 2 - old_name
copy() {
    echo "$pation_info"
    cp "${vms_path}/$2.qcow2" "${vms_path}/$1.qcow2" 
}

# Input: 1 - diskname
remove_vm() {
    rm "${vms_path}/$1.qcow2"
}

# Input: 1 - source (with extension)
remove_source() {
    rm "${source_path}/$1"
}

# Input: 1 - diskname
create_disk() {
    qemu-img create -f qcow2 "${vms_path}/$1.qcow2" 20G
}

# Input: 1 - outputname, 2 - inputname
convert_vdi() {
    qemu-img convert -f vdi -O qcow2 "${source_path}/$2" "${vms_path}/$1.qcow2"
}

# Input: 1 - diskname, 2 - source (with extension)
eval_and_run(){
    extension="${2##*.}"
    # process depending on extension
    case $extension in 
        7z)
            7z x "${source_path}/$2" -o "$source_path"
            echo "$archive_info"
            exit 0
            ;;
        iso) 
            create_disk "$1"
            # save the used base installation the the file
            setfattr -n user.base -v "$2" "${vms_path}/$1.qcow2"
            install "$1" "$2"
            exit 0
            ;;
        vdi)
            echo "$pation_info"
            qemu-img convert -f vdi -O qcow2 "${source_path}/$2" "${vms_path}/$1.qcow2"
            # save the used base installation the the file
            setfattr -n user.base -v "$2" "${vms_path}/$1.qcow2"
            run "$1"
            exit 0
            ;;
        *)
            echo $filetype_error
            remove_source "$2"
            exit 1
            ;;
    esac
}

# Input: 1 - diskname
run() {
    qemu-system-x86_64 \
        -enable-kvm \
        -cpu host \
        -m 4G \
        -smp 2 \
        -drive file="${vms_path}/$1.qcow2",format=qcow2,if=virtio \
        -boot d \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        -device virtio-rng-pci
}

# Input: 1 - diskname
run_no_graphics() {
    qemu-system-x86_64 \
        -enable-kvm \
        -cpu host \
        -m 4G \
        -smp 2 \
        -drive file="${vms_path}/$1.qcow2",format=qcow2,if=virtio \
        -boot d \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        -device virtio-rng-pci \
        -nographic
}

# Input: 1 - diskname, 2 - source (with extension)
install() {
    qemu-system-x86_64 \
        -enable-kvm \
        -cpu host \
        -m 4G \
        -smp 2 \
        -drive file="${vms_path}/$1.qcow2",format=qcow2,if=virtio \
        -boot d \
        -cdrom "${source_path}/$2" \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        -device virtio-rng-pci
}

# ---------------------------------- setup and definitions -------------------------------

# Define error texts
syn_error="[Syntax Error]: There is a problem with your syntax. Please use 'v -h' or 'v -m'."
not_found_error="[Not Found]: The file, folder or path was not found."
is_present_error="[File already exists]: The vm already exists."
source_is_present_error="[File already exists]: The source file already exists."
filetype_error="[File Type Error]: This type of file is not supported."

# Define question text
confirm_quest="[y|N]: Are you sure you want to delete or override the file?"

# Define information text
pation_info="[Note]: This can take a while. Please be patient."
archive_info="[Info]: You downloaded a ziped folder. 
Please use 'v -l' to check output and select your desiered file with 'v [vm] -i [desierd file].' 
Please use 'v -h' or 'v -m' for more information."

# Define paths
base_path="/home/user/ShortVM/"
vms_path="${base_path}vms/"
source_path="${base_path}source/"

# Check and create directories
check_and_create_folders "$base_path"
check_and_create_folders "$vms_path"
check_and_create_folders "$source_path"

# ---------------------------------- for zero parameters ----------------------------------
if [ $# -eq 0 ]; then
    run "$(basename "$(ls -ut $vms_path | head -n 1)" | sed 's/\.[^.]*$//')"
    exit 0
fi

# --------------------------------------- commands ----------------------------------------
case $1 in
    -l)
        tree -sh "$base_path"
        exit 0
        ;;
    -h)
        echo "v"
        echo "v     [name]"
        echo "v     -l"
        echo "v     -h"
        echo "v     -m"
        echo "v     -rm     [name]"
        echo "v     -rms    [source]"
        echo "v     -i      [source]    [name]"
        echo "v     -iw     [url]       [name]"
        echo "v     -t      [name]"
        echo "v     -iwt    [url]"
        echo "v     -it     [source]"
        echo "v     -d      [old_name]  [old_name]"
        echo "v     -ds     [old_name]  [old_name]"
        echo "v     -v      [name]"
        echo "v     -ng     [name]"
        echo "v     -f      [name]"
        exit 0
        ;;
    -m)
        echo "Folders:                              $base_path, $source_path, $vms_path"
        echo "Supported formats:                    iso, vdi"
        echo "Commands:"
        echo "v                                     reopen the last vm"
        echo "v     [name]                          start a specified vm from the vms folder"
        echo "v     -l                              list the folder structure"
        echo "v     -h                              short help"
        echo "v     -m                              long help"
        echo "v     -rm     [name]                  remove the specified vm"
        echo "v     -rms    [source]                remove the specified source"
        echo "v     -i      [source]    [vm]        install a vm from the source folder"
        echo "v     -iw     [source]    [vm]        install a vm from a url"
        echo "v     -t      [name]                  open a temporary vm from the vm folder as copy that gets deleted after closing"
        echo "v     -it     [source]                install a temporary vm from the source folder as copy that gets deleted after closing"
        echo "v     -iwt    [url]       [name]      install a temporary vm from a urls folder as copy that gets deleted after closing"
        echo "v     -d      [old_name]  [new_name]  duplicate a vm"
        echo "v     -ds     [old_name]  [new_name]  duplicate and open the duplicated vm"
        echo "v     -v      [name]                  save a version of the specified vm and start the original"
        echo "v     -ng     [name]                  start a vm without graphics"
        echo "v     -f      [name]                  replace a vm with a fresh installation (same base system)"
        exit 0
        ;;
    -v)
        vm=$2
        if present_vms "$vm"; then
            copy "${vm}_$(date +%T)" "$vm"
            run "$vm"
            exit 0
        else
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -rm)
        vm=$2
        if present_vms "$vm"; then
            echo $confirm_quest
            read confirm
            if [ $confirm == "y" ]; then 
                remove_vm "$vm"
                exit 0
            else 
                exit 0
            fi
        else
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -rms)
        vm=$2
        if present_source "$vm"; then
            echo $confirm_quest
            read confirm
            if [ $confirm == "y" ]; then 
                remove_source "$vm"
                exit 0
            else 
                exit 0
            fi
        else
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -ng)
        vm=$2
        if present_vms "$vm"; then
            run_no_graphics "$vm"
            exit 0
        else
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -f)
        vm=$2
        if present_vms "$vm"; then
            echo confirm_quest
            read confirm
            if [ confirm == "y" ]; then 
                remove_vm "$vm"
            else 
                exit 0
            fi
            install "$vm" getfattr -n user.base "${vms_path}/$vm.qcow2"
            exit 0
        else
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -i) 
        source=$2
        vm=$3
        if ! present_vms "$vm" && present_source "$source"; then
            eval_and_run "$vm" "$source"
            exit 0
        else
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -iw)
        source=$2
        vm=$3
        # get the file name from the url
        filename=$(basename "$source")
        if ! present_source "$filename"; then
            if ! present_vms "$vm"; then
                wget -P "$source_path" "$source"
                eval_and_run "$vm" "$filename"
                exit 0
            else
                echo "$not_found_error"
                exit 1
            fi
        else
            echo "$source_is_present_error"
            exit 1
        fi
        ;;
    -t)
        vm=$2
        if present_vms "$vm"; then
            copy "temp" "$vm"
            run "$vm"
            remove_vm "$vm"
            exit 0
        else 
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -it)
        source=$2
        if present_source "$source"; then
            eval_and_run "temp" "$source"
            remove_vm "temp"
            exit 0
        else
            echo "$not_found_error"
            exit 1
        fi
        ;;
    -iw)
        source=$2
        # get the file name from the url
        filename=$(basename "$source")
        if ! present_source "$filename"; then
            wget -P "$source_path" "$source"
            eval_and_run "temp" "$filename"
            remove_vm "temp"
            exit 0
        else
            echo "$source_is_present_error"
            exit 1
        fi
        ;;
    -d)
        new_name=$2
        vm=$3
        if ! present_vms "$vm" && present_vms "$new_name"; then
            copy "$vm" "$new_name"
            exit 0
        else 
            echo "$is_present_error"
            exit 1
        fi
        ;;
    -ds)
        new_name=$2
        vm=$3
        if ! present_vms "$vm" && present_vms "$new_name"; then
            copy "$vm" "$new_name"
            run "$vm"
            exit 0
        else 
            echo "$is_present_error"
            exit 1
        fi
        ;;
    *)
        vm=$2
        if present_vms "$vm"; then
            run "$vm"
            exit 0
        else 
            echo "$not_found_error"
            exit 1
        fi
        ;;
esac
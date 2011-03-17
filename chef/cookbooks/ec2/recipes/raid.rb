if node.attribute?('ec2')
  package "mdadm"
  package "xfsprogs"

  template "/root/fdisk" do
    source "fdisk.rb"
    owner "root"
    group "root"
    mode "0644"
  end

  block_device_index = 0
  block_device_count = 0
  block_device_list = ""
  while node[:ec2] and node[:ec2].has_key?("block_device_mapping_ephemeral#{block_device_index}") do
    block_device = node[:ec2]['block_device_mapping_ephemeral' + block_device_index.to_s]
    if not block_device.start_with?('/dev/')
      block_device = '/dev/' + block_device
    end
    if File.exists?(block_device)
      execute "fdisk #{block_device_count}" do
        command "/sbin/fdisk #{block_device} < /root/fdisk"
        not_if { File.exists?("/dev/md0") }
      end
      block_device_list += "#{block_device}1 "
      block_device_count += 1
    end
    block_device_index += 1
  end

  bash "unmount" do
    code <<-EOH
      umount /mnt
      rmdir /mnt
      grep -v /mnt /etc/fstab > /tmp/fstab
      mv /tmp/fstab /etc/fstab
    EOH
    only_if { block_device_count > 1 }
    not_if { FileTest.exists?("/dev/md0") }
  end

  bash "mdadm" do
    code <<-EOH
      mdadm --create /dev/md0 --level 0 --metadata=1.1 --raid-devices=#{block_device_count} #{block_device_list}
      echo DEVICE #{block_device_list} >> /etc/mdadm/mdadm.conf
      mdadm --detail --scan >> /etc/mdadm/mdadm.conf
      mkfs.xfs /dev/md0
      echo -e '/dev/md0\t/mnt\txfs\tnoatime\t0\t0' >> /etc/fstab
      mkdir /mnt
      mount /mnt
    EOH
    only_if { block_device_count > 1 }
    not_if { File.exists?("/dev/md0") }
  end
end
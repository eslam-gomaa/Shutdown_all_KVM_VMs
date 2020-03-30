require 'open4'
require 'timeout'


$wait    = true
$wait_timeout = 120

def exec_cmd(cmd)
  info = {}
  info[:cmd] = cmd
  status   = Open4::popen4(cmd) do |pid,stdin,stdout,stderr|
    info[:stderr] = stderr.read.strip
    info[:stdout] = stdout.read.strip
    info[:pid]    = pid
  end
  info[:exit_status] = status.exitstatus
  info
end

# Color
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end
  def red
    colorize(31)
  end

  def green
    colorize(32)
  end
end

def list_opened_vms
  list = exec_cmd('virsh list')
  if list[:exit_status] > 0
    STDOUT.puts "[ ERROR ] Failed to list Opened VM's"
    STDOUT.puts "\t => " + list[:stderr]
    exit(1)
  end

  filter = list[:stdout].gsub(/Id\s+Name\s+State\n-+/, '')
  filter_ = filter.gsub(/^\n/, '')
  names = filter_.gsub("\s\s\s\s", "\s").split("\n")
  result = []
  for n in names do
    f = n.split("\s")
    #result << n - n[0]
    result << f.delete_at(1)
  end
  result
end

def shutdown_vm(vm)
  c = exec_cmd("virsh shutdown #{vm}")
  if c[:exit_status] != 0
    STDERR.puts "[ ERROR ] Failed to shutdown #{vm}"
    STDERR.puts "\t\t => #{c[:stderr]}"
  else c[:exit_status] == 0
  puts "\t => shutdown VM: (#{vm}) " + "[Ok]".green
  end
end

def shutdown_vm_list(array)
  if array.length < 1
    puts "[ INFO ] All VM's already --> shutdown"
  else array.length >= 1
  puts "[ INFO ] shutting down opened VM's"
  for vm in array
    shutdown_vm(vm)
  end
  if $wait == true
    count = 1
    Timeout::timeout($wait_timeout) do
      until list_opened_vms.length == 0
        printf("\r[ INFO ] Waiting for all the VM's to shut down " + "#{count}".red + "/s   " )
        count = count + 1
        sleep(1)
      end
    end
    puts
  end
  end
end


vm_list =  list_opened_vms
shutdown_vm_list(vm_list)

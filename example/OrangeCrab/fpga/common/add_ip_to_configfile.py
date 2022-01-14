import sys

CONFIG_FILE_NAME = ''
IP_ADDRESS = []
SUBNET_MASK = []
GATEWAY = []


def parse_command_line():    
    global CONFIG_FILE_NAME
    global IP_ADDRESS
    global SUBNET_MASK
    global GATEWAY
    CONFIG_FILE_NAME = sys.argv [1]    
    IP_ADDRESS = sys.argv[2]    
    SUBNET_MASK = sys.argv[3]    
    GATEWAY = sys.argv[4]    


def write_ip_to_file(ipAddress):
    global CONFIG_FILE_NAME
    with open(CONFIG_FILE_NAME, "r") as file:
        new_line = file.read().replace('.comment ', '.comment '+ipAddress)
    with open('fpga_out.config', "w") as file:
        file.write(new_line)


def process_ip_address():
    global IP_ADDRESS
    global SUBNET_MASK
    global GATEWAY
    ipAddr = IP_ADDRESS.split(".")
    subNetMAsk = SUBNET_MASK.split(".")
    gateWay = GATEWAY.split(".")
    address = ""
    for j in ipAddr+subNetMAsk+gateWay:        
        i = int(j)
        address += chr(((i & 0x0F) + 0x40))
        address += chr((((i >> 4) & 0x0F) + 0x40))
    return address


parse_command_line()
ipAddress = process_ip_address()
write_ip_to_file(ipAddress)


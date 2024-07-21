import random
import struct

# 013c old checksum not ffbb  24    74      ffbb   68e0
# ff3f old dscp not     ffbf  ff57  ff07    ff6f   ff9b
# 84 new dscp           d0    4c    60      f4          88      9c   b0   18    4c

# f 0150 old chc
# f ff2b    ffc8 
# 84
# feff 

def my_checksum_calc(old_dscp, old_checksum, new_dscp):
    """
    Calculate the IPv4 header checksum.
    :param header: The IPv4 header as a bytes object
    :return: The checksum as an integer
    """
    checksum = (~old_checksum) & 0xFFFF

    old_dscp2 = old_dscp + 0x100
    part2    = (~(old_dscp2 & 0xFFFC)) & 0xFFFF
    checksum = checksum + part2 

    checksum = (checksum >> 16) + (checksum & 0xFFFF)
    checksum += ((checksum >> 16) & 0xFFFF)

    # part2    = (~(1 << 8)) & 0xFFFF
    # checksum = checksum + part2 

    # checksum = (checksum >> 16) + (checksum & 0xFFFF)
    # checksum += ((checksum >> 16) & 0xFFFF)

    # print(f"checksum 2 {checksum:05X}")
    checksum = checksum + (new_dscp & 0xFC)
    # print(f"checksum 3 {checksum:05X}")
    checksum = (checksum >> 16) + (checksum & 0xFFFF)
    checksum += (checksum >> 16)
    # One's complement
    checksum = (~checksum) & 0xFFFF
    # checksum = (checksum + (1 << 8))
    # checksum = (checksum >> 16) + (checksum & 0xFFFF)
    # checksum += (checksum >> 16)

    
    # checksum = (checksum >> 16) + (checksum & 0xFFFF)
    # checksum += (checksum >> 16)

    return checksum

def calculate_checksum(header: bytes) -> int:
    """
    Calculate the IPv4 header checksum.
    :param header: The IPv4 header as a bytes object
    :return: The checksum as an integer
    """
    # Ensure the header length is a multiple of 2 bytes
    if len(header) % 2 == 1:
        header += b'\0'

    checksum = 0
    for i in range(0, len(header), 2):
        word = (header[i] << 8) + header[i + 1]
        checksum += word

    # Add carry if any
    checksum = (checksum >> 16) + (checksum & 0xFFFF)
    checksum += (checksum >> 16)

    # One's complement
    checksum = ~checksum & 0xFFFF

    return checksum


def parse_ipv4_header(header: bytes):
    """
    Parse and print the fields of an IPv4 header.
    :param header: The IPv4 header as a bytes object
    """
    fields = struct.unpack('!BBHHHBBH4s4s', header[:20])

    version_ihl = fields[0]
    version = version_ihl >> 4
    ihl = version_ihl & 0x0F
    dscp_ecn = fields[1]
    dscp = dscp_ecn >> 2
    ecn = dscp_ecn & 0x03
    total_length = fields[2]
    identification = fields[3]
    flags_fragment_offset = fields[4]
    flags = flags_fragment_offset >> 13
    fragment_offset = flags_fragment_offset & 0x1FFF
    ttl = fields[5]
    protocol = fields[6]
    header_checksum = fields[7]
    source_ip = fields[8]
    dest_ip = fields[9]

    print(f"Version: {version}")
    print(f"IHL (Header Length): {ihl * 4} bytes")
    print(f"DSCP: {dscp:04X}")
    print(f"ECN: {ecn:04X}")
    print(f"Total Length: {total_length:04X}")
    print(f"Identification: {identification:04X}")
    print(f"Flags: {flags:04X}")
    print(f"Fragment Offset: {fragment_offset:04X}")
    print(f"TTL (Time to Live): {ttl:04X}")
    print(f"Protocol: {protocol:04X}")
    print(f"Header Checksum: {header_checksum:#04x}")
    print(f"Source IP: {'.'.join(map(str, source_ip))}")
    print(f"Destination IP: {'.'.join(map(str, dest_ip))}")




def randomize_dscp_ttl(header: bytes, random_ttl= True) -> bytes:
    """
    Randomize the DSCP and TTL fields of an IPv4 header.
    :param header: The original IPv4 header as a bytes object
    :return: The modified IPv4 header with randomized DSCP and TTL
    """
    # Copy the header to modify it
    new_header = bytearray(header)
    
    # Randomize the DSCP (bits 0-5 of the second byte)
    new_header[1] = (new_header[1] & 0x03) | (random.randint(0, 63) << 2)
    
    # Randomize the TTL (byte 8)
    if random_ttl:
        new_header[8] = random.randint(1, 255)
    else:
        new_header[8] = header[8] - 1 if header[8] > 0 else 0 
    
    # Set checksum to 0 before recalculating
    new_header[10] = 0
    new_header[11] = 0
    
    # Calculate the new checksum
    checksum = calculate_checksum(new_header)
    
    # Insert the checksum into the header
    new_header[10] = (checksum >> 8) & 0xFF
    new_header[11] = checksum & 0xFF
    
    return bytes(new_header)


# Example IPv4 packet header (20 bytes for standard header without options)
# Example header: Version (4) + IHL (5) + DSCP/ECN (0) + Total Length (20)
# Identification (0) + Flags/Fragment Offset (0) + TTL (64) + Protocol (TCP/6)
# Header Checksum (to be calculated, set to 0) + Source IP (192.168.1.1)
# Destination IP (192.168.1.2)
ipv4_header = bytes([
    0x45, 0x11, 0x00, 0x27,
    0x6D, 0xAF, 0x09, 0x9E,
    0x3D, 0x11, 0x00, 0x00,  # Checksum field initially set to 0
    0x48, 0x96, 0x6D, 0xD0,
    0xA6, 0x47, 0xA3, 0x46
])
# my_num = 0xD5
# print(f"{(~(my_num & 0xFC))&0xFFFFF:08X}")
# exit(0)
#C9
# parse_ipv4_header(ipv4_header)
# my_checksum     =   calculate_checksum(ipv4_header)
# print(hex(my_checksum))
# new_header      =   bytearray(ipv4_header)
# old_checksum    =   (new_header[10] << 8) + (new_header[11])
# old_dscp        =   new_header[1]
# print(f"old checksum {old_checksum}")
# print(f"old dscp {old_dscp:04X}")
# custom_checksum = my_checksum_calc(old_checksum=0x0674, old_dscp=old_dscp, new_dscp=0xC9)
# print(f"Custom checksum val {custom_checksum:04X}")
# new_header[1] = 0xC9
# ipv4_header = bytes(new_header)
# my_checksum = calculate_checksum((ipv4_header))
# print(hex(my_checksum))

# parse_ipv4_header(ipv4_header)
for i in range(0, 400000):
    ipv4_header = randomize_dscp_ttl(ipv4_header, random_ttl= True)
    randomized = randomize_dscp_ttl(ipv4_header, random_ttl= False)
    
    old_ttl = ipv4_header[8]
    old_dscp = (ipv4_header[1])
    old_checksum = (ipv4_header[10] << 8) + ipv4_header[11]
    new_dscp = randomized[1]
    new_ttl = randomized[8]
    new_checksum = ((randomized[11] & 0xFF))
    new_checksum = new_checksum + ((randomized[10] & 0xFF) << 8)
    my_checksum = my_checksum_calc(old_dscp=old_dscp, old_checksum=old_checksum, new_dscp=new_dscp)
    if (i % 1000) == 0:
        print(f"Old TTL:0x{old_ttl:04X}, New TTL:0x{new_ttl:04X}, Old DSCP: 0x{old_dscp:04X}, Old Checksum: 0x{old_checksum:04X}, New DSCP: 0x{new_dscp:04X}, New Checksum: 0x{new_checksum:04X}, My Checksum: 0x{my_checksum:04X}")
    if(my_checksum != new_checksum):
        print(f"Old TTL:0x{old_ttl:04X}, Old DSCP: 0x{old_dscp:04X}, Old Checksum: 0x{old_checksum:04X}, New DSCP: 0x{new_dscp:04X}, New Checksum: 0x{new_checksum:04X}, My Checksum: 0x{my_checksum:04X}")
        print(f"Error {i}")  
        exit()

print("No Error")
exit(0)

    
# # Print the original header
# print("Original IPv4 Header:")
# parse_ipv4_header(ipv4_header)

# # Print the modified header
# print("\nModified IPv4 Header:")
# parse_ipv4_header(randomized)


# print(old_dscp, old_ttl, old_checksum, new_dscp)
# print(f"\n My Checksum: {my_checksum:#04x}")

# # Calculate the checksum
# checksum = calculate_checksum(ipv4_header)
# checksum.to_bytes(2, byteorder='big')
# print(f"Calculated Checksum: 0x{checksum:04X}")

# # Insert the checksum into the header
# ipv4_header_with_checksum = (
#     ipv4_header[:10] +
#     checksum.to_bytes(2, byteorder='big') +
#     ipv4_header[12:]
# )

# print(f"IPv4 Header with Checksum: {ipv4_header_with_checksum.hex()}")

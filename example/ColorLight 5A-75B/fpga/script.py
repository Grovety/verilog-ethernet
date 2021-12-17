# nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json $< --textcfg $@ --lpf ../$(BOARD).lpf --freq 166 --log PlaceAndRoute.log --seed 3
# nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json fpga.json --textcfg fpga_out.config --lpf ../pinout_v7.lpf --freq 166 --log PlaceAndRoute.log --seed 3

# nextpnr-ecp5 
# --25k 
# --package CABGA256 
# --speed 6 
# --json fpga.json 
# --textcfg fpga_out.config 
# --lpf ../pinout_v7.lpf 
# --freq 166 
# --log PlaceAndRoute.log 
# --seed 3


import sys
import os


def parse_command_line():
    key = ''
    value = ''
    skip = False
    params = {}
    for param in sys.argv [1:]:
        if '--' in param:
            key = param
            params[key] = ''
        else:
            value = param
            params[key] = value    
    return params


def prepare_comand(parameters):
    command = 'nextpnr-ecp5'
    for key, value in parameters.items():
        if key == '--times' or key == '--seed':
            continue
        command += ' ' + key + ' ' + value
    return command


# This function parses nextpnr's output log
# 
# Returns result as a dictionary: 
# key - signal name
# values - it's frequency and if it satisfies FMax (PASS/FAIL)
def parse_log(file_name):
    results = {} # Stores name of signal, it's frequency and if it satisfies FMax (PASS/FAIL)
    with open(file_name, 'r') as file:
        for line in file:            
            if 'Max frequency for clock' in line:
                # Split obtained lines to get values
                tmp = line.split()
                key = tmp[5]
                freq = tmp[6]
                is_passed = tmp[8][1:] # Ignore first symbol in the word since it is '('
                FMax = tmp[10]
                results[key] = [freq, is_passed, FMax] # Add or rewrite resulting value
    return results


def estimate(results):
    estimation = 0
    count = 0
    for signal in results.values():
        freq = signal[0]
        FMax = signal[2]
        estimation += float(freq)/float(FMax)
        count += 1
    return estimation/count

def test_estimate():
    # 175.35 PASS 25.00
    lhs_signal = {'signal1' : ['100.0', 'FAIL', '125.0'],
                  'signal2' : ['100.0', 'FAIL', '125.0'],
                  'signal3' : ['100.0', 'FAIL', '125.0']
                 }
    res = estimate(lhs_signal)
    print (res)


def is_better(lhs_signal, rhs_signal):
    res = True
    if bool(rhs_signal) != True:
        return True

    lhs_value = estimate(lhs_signal)
    rhs_value = estimate(rhs_signal)
    res = True if lhs_value > rhs_value else False
    return res

def test_is_better():
    lhs_signal = {'signal1' : ['100.0', 'FAIL', '125.0'],
                'signal2' : ['100.0', 'FAIL', '125.0'],
                'signal3' : ['100.0', 'FAIL', '125.0']
                }
    rhs_signal = {'signal1' : ['110.0', 'FAIL', '125.0'],
                'signal2' : ['110.0', 'FAIL', '125.0'],
                'signal3' : ['110.0', 'FAIL', '125.0']
                }
    res = is_better(lhs_signal, rhs_signal)
    print (res)


def find_best(command, cli_params):
    best_seed = 0
    best_results = {}

    times = 7 # Default value
    log_file = './Logfile.log' # default log file    
    if '--times' in cli_params:
        times = cli_params['--times']
    if '--log' in cli_params:
        log_file = cli_params['--log']
    else:
        cli_params['--log'] = log_file

    # Run nextpnr several times with different seeds to obtain the best frequences
    for i in range (1,int(times)+1):        
        print ('------------------------------------------------------------------------------------')
        print ('Attempt to run NEXTPNR # ', i)
        print ('------------------------------------------------------------------------------------')
        os.system (command + ' --seed ' + str(i))
        
        cur_results = parse_log(log_file)
        # Ceck if all frequences satisfy FMax
        proceed = False
        for is_pass in cur_results.values():
            if is_pass[1] == 'FAIL':
                # If at least 1 frequence does not satisfy FMax, there is no reason to
                # check other frequences and we should try other seeds
                proceed = True
                break
        # If all frequences satisfy FMax, should not proceed searching the best result   
        if proceed == False:
            best_seed = i
            break
        else:
            # Some frequences do not satisfy FMax. Let's try to choose the best one
            if is_better(cur_results, best_results):
                best_results = cur_results
                best_seed = i
    else:        
        print ('------------------------------------------------------------------------------------')
        print ('Final runing NEXTPNR')
        print ('------------------------------------------------------------------------------------')
        os.system (command + ' --seed ' + str(best_seed))
    print ("Best seed is: ", best_seed)
    return best_seed



cli_params = parse_command_line()
command = prepare_comand(cli_params)    
seed = find_best(command, cli_params)

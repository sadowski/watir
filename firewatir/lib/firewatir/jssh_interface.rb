=begin rdoc
  This is the JSSH connector used by Firewatir to connect to Firefox.  
=end
class JSSHInterface
  attr_reader :socket, :host, :port
  
  # Constant representing the JSSH command prompt appended to the end of each command
  JSSH_COMMAND_PROMPT = "\n> "
  
  # Time to wait in Kernel#select for data
  SOCKET_DATA_TIMEOUT = 1
  
  #
  # Description:
  # Creates a new instance of the class and optionally connects to the browser.
  #
  # Input:
  # host - the hostname / IP address of the machine running Firefox (default: 127.0.0.1).
  # port - the port JSSH is running on (default: 9997).
  #
  def initialize(host="127.0.0.1", port=9997, establish_connection=true)
    @host = host
    @port = port
    
    # Establish connection to browser
    connect if establish_connection
  end
  
  # This function creates a new socket at port 9997 and sets the default values for instance and class variables.
  # Raises a UnableToStartJSShException if cannot connect to jssh even after 3 tries.
  def connect(no_of_tries = 0)
    # Create a new socket to connect to it using the configured settings.
    begin
      @socket = TCPSocket::new(@host, @port)
      @socket.sync = true
      read_socket()
    rescue
      no_of_tries += 1
      retry if no_of_tries < 3
      raise Watir::Exception::UnableToStartJSShException, "Unable to connect to machine : #{@host} on port #{@port}. Make sure that JSSh is properly installed and Firefox is running with '-jssh' option"
    end
  end
  private :connect
  
  #
  # Description:
  # Disconnects the JSSH connection.
  #
  def disconnect()
    # Close the socket
    @socket.close
  end
  
  #
  # Description:
  # Prepares javascript for submission to JSSH plugin.
  # Removes new line characters from within the code and ensures that it ends with a terminating new line. This triggers the execution of the code.
  #
  # Inputs:
  # command - the Javascript command to execute.
  def prepare_command(command)
    # Remove new lines applied during formatting
    command.gsub!("\n", "")
    
    # Return the command with terminating new line added.
    return "#{command}\n"
  end
  private :prepare_command
  
  # 
  # Description:
  # Executes the provided command and return result.
  #
  # Inputs:
  # command - the JSSH command to execute.
  #
  def execute(command)
    # TCP Socket options
    socket_flags = 0
    
    # Send the command
    @socket.send(prepare_command(command), socket_flags)
    
    # Return the result
    return read_socket()
  end
  
  # Evaluate javascript and return result. Raise an exception if an error occurred.
  def js_eval(command)
    value = execute(command)
    if md = /^(\w+)Error:(.*)$/.match(value) 
      eval "class JS#{md[1]}Error < StandardError\nend"
      raise (eval "JS#{md[1]}Error"), md[2]
    end
    value
  end
  
  #
  # Description:
  #  Reads the javascript execution result from the jssh socket. 
  #
  # Output: 
  # The javascript execution result as string.  
  #
  def read_socket()
    return_value = ""
    
    # Wait until data becomes available on the socket
    socket_data = Kernel.select([@socket], nil, nil, SOCKET_DATA_TIMEOUT) until socket_data
    
    # Read from the read stream (element 0) of the socket_data
    # and append the data to the return value until we encounter 
    # a JSSH command prompt
    for stream in socket_data[0]
      until return_value.include?(JSSH_COMMAND_PROMPT) do
        return_value += stream.recv(1024)
      end
    end
    
    # Remove the JSSH command prompts
    return_value.gsub!(Regexp.new(JSSH_COMMAND_PROMPT), '')
    
    # Return the result
    return return_value
  end
  private :read_socket
  
end

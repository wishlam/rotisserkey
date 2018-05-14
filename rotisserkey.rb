require 'aws-sdk'
require 'securerandom'
require 'colorize'

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
})
iam = Aws::IAM::Client.new

keys = iam.list_access_keys

# Confirm only one key
if keys.access_key_metadata.count == 1
  puts
  puts "This ruby script rotates AWS API keys."
  puts
  puts "Your current key: \"#{keys.access_key_metadata[0].access_key_id}\" will be set to inactive: "
  puts "Is this alright? y/n"
  puts
  # Take in input
  prompt = gets.chomp
  if prompt == "y"

    # Set inactive
    iam.update_access_key({access_key_id: "#{keys.access_key_metadata[0].access_key_id}", status: "Inactive",})

    puts "************************"
    puts "*"
    puts "* OLD KEY IS INACTIVE!"
    puts "*"
    puts "************************"
    puts
    puts "Creating second access key......"
    puts
    new_key = iam.create_access_key
    puts "OK, key created. Store this somewhere, because this isn't saved and won't show up again!:"
    puts
    puts "*****************************************************************************************************"
    puts "*"
    puts "* \tNEW KEY - status: \t\t\t#{new_key.access_key.status}"
    puts "* \tNEW KEY - access key id: \t\t#{new_key.access_key.access_key_id}"
    puts "* \tNEW KEY - secret access key id: \t#{new_key.access_key.secret_access_key}"
    puts "* \tNEW KEY - creation date: \t\t#{new_key.access_key.create_date}"
    puts "*"
    puts "* UPDATE YOUR \"~/.aws/credentials\", \"~/.bash_profile\" AND POSSIBLY ANY OTHER CONFIGS THAT"
    puts "* USE YOUR KEYS AT THIS TIME!"
    puts "* "
    puts "* YOU MAY HAVE TO RELOAD YOUR TERMINAL WINDOWS."
    puts "*****************************************************************************************************"
    puts

    puts "This next step will delete your old key!"
    puts
    puts "To delete your old key, copy and paste the following randomly generated string without quotes EXACTLY: "

    # Need to reload with new keys to delete. User should have updated their files by now.
    ENV.clear
    Aws.config.update({
      region: 'us-east-1',
      credentials: Aws::Credentials.new("#{new_key.access_key.access_key_id}","#{new_key.access_key.secret_access_key}")
    })
    iam2 = Aws::IAM::Client.new

    # Create random string for confirmation
    random = SecureRandom.base64()
    p random
    delete = gets.chomp

    if delete == random
      iam2.delete_access_key({access_key_id: "#{keys.access_key_metadata[0].access_key_id}",})
      puts "****************************"
      puts "*"
      puts "* Deleted old access key."
      puts "*"
      puts "****************************"
      puts
      puts "KEYS ROTATED SUCCESSFULLY!".green
    else
      puts "Full stop, not deleting, kthxbai.".red
    end
  else
    puts 
    puts "Quitting!!"
    puts
  end
else
  puts
  puts "This script has detected that you have two AWS API keys, which is the limit. We can't rotate keys.".red
  puts
  puts "You need to remove one through the AWS console.".red
  puts
end

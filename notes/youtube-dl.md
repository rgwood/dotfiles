# Limit to 1080p: 
--format 'bestvideo[height<=1080]+bestaudio/best[height<=1080]'

# Check format, do not actually download file:
--get-format

# Best audio (warning: might be webm)
--format 'bestaudio'

# Best m4a audio
--format 'm4a'
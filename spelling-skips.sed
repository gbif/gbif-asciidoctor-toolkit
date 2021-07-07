# Remove document attributes
/^:[a-zA-Z0-9!_-]+: ?.*$/d
# Remove macro key and value, but leave attributes
s/[a-z0-9-]+::?[a-z0-9./_-]+\[/[/ig
# Remove some macro attributes
s/(align|width|height)="?[a-z0-9]+"?(,|\])?//ig
# Remove role attributes
s/^\["?(multipage|lowerroman|upperroman|loweralpha|arabic|vimeo|youtube)"?,?/[/
# Remove iframes
s/<iframe.*?<\/iframe>//g
# Remove comments
s/^\/\/.+//g

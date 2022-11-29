# Sample ERC 721 

Need to create ERC721 contract

- Contract should have baseUri (ipfs://asdf.com/project) set from constructor
- Each asset should have its id after baseUri (ipfs://asdf.com/project/23)
- Contract tokens can be minted only by the owner
- Contract should have all unit tests
- Each asset should have Experience, rank
- There should be a required experience amount for each rank
- User should manually rank up token when it gets enough experience
- User can gain experience by locking token
- Locked token can't be unlocked (Before time), and can't be interacted (send, burn etc)
- You should decide how much XP token will gain for a lock
- User should manually unlock token
- If user should have a method to kill token(and transfer 80% of it's exp to other token)
- Explicit burn of token should be blocked for everyone
BitLoTop Airdorp — HTML Version

This is a single-file HTML + JS airdrop frontend (sequential transfers).

Files:
- index.html  -> upload to https://bitlo.top/airdorp/index.html
- sample_recipients.csv -> example CSV format

Usage:
1. Upload index.html to your GitHub Pages folder (e.g., docs/airdorp/index.html) or host at /airdorp.
2. Open the page, click 'Load token' to confirm token info.
3. Upload or paste CSV with lines: address,amount
4. Connect MetaMask when prompted and click 'Start Airdrop' to begin sequential transfers.
5. Test with 2-3 addresses first!

Notes:
- This version sends one transfer per recipient (no multisend contract).
- Make sure the connected wallet holds the tokens and BNB for gas.
- The page is set to noindex (private).

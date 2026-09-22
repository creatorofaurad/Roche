const fs = require('fs');

async function getCode(address, rpcUrl = 'https://ethereum-rpc.publicnode.com') {
  const res = await fetch(rpcUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'eth_getCode',
      params: [address, 'latest'],
      id: 1
    })
  });
  const data = await res.json();
  return data.result;
}

async function main() {
  const targets = {
    cbeth_proxy: '0xBe9895146f7AF43049ca1c1AE358B0541Ea49704',
    cbeth_impl: '0x31724ca0c982a31fbb5c57f4217ab585271fc9a5',
    base_l1_messenger: '0x866E82a600A1414e583f7F13623F1aC5d58b0Afa',
    cbbtc_eth: '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf'
  };

  if (!fs.existsSync('corpus')) fs.mkdirSync('corpus');

  for (const [name, addr] of Object.entries(targets)) {
    console.log(`Fetching ${name} (${addr})...`);
    try {
      const code = await getCode(addr);
      fs.writeFileSync(`corpus/${name}.hex`, code);
      console.log(`Saved ${name}.hex (${code.length / 2} bytes)`);
    } catch (e) {
      console.error(`Error fetching ${name}:`, e.message);
    }
  }
}

main();

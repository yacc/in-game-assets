const fs = require('fs-extra')
const path = require('path')

async function main() {

  const ABIs = {
    when: (new Date).toISOString(),
    contracts: {}
  }

  const contractsDir = await fs.readdir(path.resolve(__dirname, '../artifacts/contracts'))

  for (let name of contractsDir) {
    let tmp = name.split('.')
    if (tmp[1] !== 'sol') continue
    name = tmp[0]
    let source = path.resolve(__dirname, `../artifacts/contracts/${name}.sol/${name}.json`)
    let json = require(source)
    ABIs.contracts[name] = json.abi
  }
  await fs.writeFile(path.resolve(__dirname, '../export/ABIs.json'), JSON.stringify(ABIs, null, 2))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });


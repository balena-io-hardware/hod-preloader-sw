const util = require('util');
const exec = util.promisify(require('child_process').exec);
const debug = require('debug')('preload')
const Constants = require(__dirname + '/constants');
const constants = new Constants();

async function getVersions() {
    const balenaVersion = await exec("balena version -j")
        .then(async (output) => {
            return await JSON.parse(output.stdout)
        });
    debug(balenaVersion)

    const dockerVersion = await exec("docker version -f json")
        .then(async (output) => {
            return await JSON.parse(output.stdout)['Server']['Version']
        });
    debug(dockerVersion)
    return [balenaVersion['balena-cli'], dockerVersion]
}

async function setup(fleet,name,release='latest',version='latest',network={},compress) {
    const version = await getVersions();
    await console.log(`versions ${version}`);
    await authenticate();
}

async function authenticate() {
    const success = await exec(`balena login --token "${constants.CLI_API_KEY}"`)
    if (!success.stderr) {
        console.log('success')
    }
}






(async () => {
    try {
        await setup();
        // console.log(text);
    } catch (e) {
        // Deal with the fact the chain failed
        console.error(e)
    }
    // `text` is not available here
})();
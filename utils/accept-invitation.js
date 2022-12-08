const { getSdk } = require('balena-sdk');
const sdk = getSdk();

(async () => {
    await sdk.auth.logout();
    await sdk.auth.loginWithToken(process.env.BALENA_API_KEY);
    const status = await sdk.models.organization.invite.accept(process.argv.slice(2));
    console.log(status)
})()


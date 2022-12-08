const express = require('express')
const basicAuth = require('express-basic-auth')
const bp = require("body-parser");
const fs = require("fs")

const app = express();
const port = 3333;
const imageDir = "./images"

if (!fs.existsSync(imageDir)) {
    fs.mkdirSync(imageDir);
}

const staticUserAuth = basicAuth({
    users: {
        'admin': 'secret1234'
    },
    challenge: false
})

app.use(bp.urlencoded({ extended: false }));
app.use(bp.json());
app.use(express.static(__dirname + '/public'));


app.use('/images', express.static('/images'));

app.post("/preload", staticUserAuth, async (req, res) => {
    console.log(req.body);

    // check if valid image

    return res.status(200).send('image preloading...')
});


app.listen(port, () => console.log(`server at port ${port}`));
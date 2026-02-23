import bcrypt from "bcrypt";

const senha = "12345";
const senha1 = "12345";
const saltRounds = 10;
const salt = await bcrypt.genSalt(saltRounds);
async function criptografar(codigo) {
    let criptografia = await bcrypt.hash(codigo, salt);
    return criptografia;
};
let dadoCriptografado = await criptografar(senha)
let dadoCriptografado1 = await criptografar(senha1)

console.log( dadoCriptografado,"\n",dadoCriptografado1);

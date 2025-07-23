import { writeFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { Features, transform } from "lightningcss";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";

const args = yargs(hideBin(process.argv))
	.command("$0 <file>", "generate critical CSS", (yargs) => {
		return yargs
			.positional("file", {
				describe: "the input file to process",
				type: "string",
			})
			.option("out", {
				describe: "output file",
				type: "string",
				alias: "o",
			});
	})
	.help()
	.parse();
readFile(args.file).then((codeBuf) => {
	const { code } = transform({
		filename: args.file,
		code: codeBuf,
		minify: true,
		include: Features.Nesting,
	});
	writeFileSync(args.out, code);
});

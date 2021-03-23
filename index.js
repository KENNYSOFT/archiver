#!/bin/node

const mysql = require("mysql2/promise");
const fetch = require("node-fetch");
const util = require("util");
const exec = util.promisify(require("child_process").exec);

const main = async () => {
    const connection = await mysql.createConnection({
        host: "localhost",
        user: "archiver",
        password: "archiver",
        database: "archiver"
    });
    connection.config.namedPlaceholders = true;
    
    const [sources] = await connection.execute("SELECT s.no, s.`type`, s.url, s.command, s.update_hook FROM archiver.source s WHERE s.active = 1 AND (s.last_checked_at IS NULL OR ADDTIME(s.last_checked_at, s.interval) < NOW());");
    
    for (const source of sources) {
        try {
            let content;

            if (source.url) {
                const res = await fetch(source.url);
                content = await res.text();
                if (res.status != 200) {
                    await connection.execute("INSERT INTO archiver.error_log (source_no, http_status_code, message) VALUES (?, ?, ?);", [source.no, res.status, content]);
                    await connection.execute("UPDATE archiver.source s SET s.last_checked_at = NOW() WHERE s.no = :no;", source);
                    continue;
                }
            } else if (source.command) {
                const {stdout} = await exec(source.command.replace(/\\\r?\n/g, " "), {shell: "/bin/bash"});
                content = stdout;
            }
            
            if (source.type === "json") {
                content = JSON.stringify(JSON.parse(content), null, 2);
            }

            const newArchive = {source_no: source.no};

            const [archives] = await connection.execute("SELECT a.revision, a.content FROM archiver.archive a WHERE a.source_no = :no AND a.content IS NOT NULL ORDER BY a.archived_at DESC LIMIT 1;", source);
            const latestArchive = archives.length > 0 ? archives[0] : {};
            if (archives.length > 0) {
                if (content === latestArchive.content) {
                    newArchive.revision = latestArchive.revision;
                    newArchive.content = null;
                } else {
                    newArchive.revision = latestArchive.revision + 1;
                    newArchive.content = content;
                }
            } else {
                newArchive.revision = 1;
                newArchive.content = content;
            }
            await connection.execute("INSERT INTO archiver.archive (source_no, revision, content) VALUES (:source_no, :revision, :content);", newArchive);

            if (newArchive.content && source.update_hook) {
                const availableObjects = {source, latestArchive, newArchive};
                await exec(source.update_hook.replace(/\\\r?\n/g, " ").replace(/\$\{(source|latestArchive|newArchive)\.([^}]+)\}/g, (_, g1, g2) => availableObjects[g1][g2]), {shell: "/bin/bash"});
            }
        } catch (e) {
            let message = e.toString();
            if (e.stdout) {
                message = e.stdout;
            }
            await connection.execute("INSERT INTO archiver.error_log (source_no, message) VALUES (?, ?);", [source.no, message]);
        }
        await connection.execute("UPDATE archiver.source s SET s.last_checked_at = NOW() WHERE s.no = :no;", source);
    }
}

main().then(() => {process.exit(0);});

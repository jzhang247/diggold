const git = require('isomorphic-git');
const fs = require('fs');
const fse = require('fs-extra')
const http = require('isomorphic-git/http/node');

const dir = './temp-repo';
const repoUrl = 'https://github.com/HMCL-dev/HMCL.git';

async function getTagCommit(tag) {
    try {
        // Resolve the tag reference
        const ref = `refs/tags/${tag}`;
        const sha = await git.resolveRef({ fs, dir, ref });

        // Check if it's an annotated tag (tag object) or lightweight tag (direct commit)
        const { type } = await git.readObject({ fs, dir, oid: sha });

        if (type === 'tag') {
            // If it's an annotated tag, read the tag object to get the commit
            const tagObject = await git.readTag({ fs, dir, oid: sha });

            console.log(tagObject);

            return tagObject.tag.object;
        }
        return sha; // If it's a lightweight tag, return directly
    } catch (error) {
        console.error(`Error resolving tag ${tag}:`, error);
        return null;
    }
}

async function cloneAndListTagsWithCommits() {


    try {
        // Clone repository
        console.log(`Cloning repository from ${repoUrl}...`);
        await git.clone({
            fs,
            http,
            dir,
            url: repoUrl,
            singleBranch: false,
            depth: undefined
        });

        // List tags and get their commits
        console.log('Listing tags with commits...');
        const tags = await git.listTags({ fs, dir });


        for (const tag of tags) {
            const commitId = await getTagCommit(tag);
            const commit = await git.readCommit({ fs, dir, oid: commitId });
            console.log(commit);
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {

    }
}

// Run the function
cloneAndListTagsWithCommits();
const matchAllHtmlTags = html => {
    const regex = new RegExp(
        '<[a-z]+>|<\/[a-z]+>|<[a-z]+\s[a-z]+|<!--|-->|<![A-Z]+\s[a-z]+>', 'g');
    return html.matchAll(regex);
}

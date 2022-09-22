export default function (text, placeholder, replacement) {
  const regex = new RegExp(`({{\s*${placeholder}\s*}})`, 'ig');
  return text.replace(regex, replacement);
}

import fs from 'fs';
const podfilePath = './ios/App/Podfile';

fs.readFile(podfilePath, 'utf8', (err, data) => {
  if (err) {
    return console.error('Error reading Podfile:', err);
  }

  const result = data.replace(/pod 'CapacitorCordova'.*/g, '');
  
  fs.writeFile(podfilePath, result, 'utf8', (err) => {
    if (err) return console.error('Error writing Podfile:', err);
    console.log('CapacitorCordova removed from Podfile');
  });
});

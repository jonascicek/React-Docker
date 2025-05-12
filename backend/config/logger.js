import winston from 'winston';

// Custom format für Zeitstempel und strukturierte Logs
const customFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss'
  }),
  winston.format.printf(({ level, message, timestamp, ...metadata }) => {
    let msg = `${timestamp} [${level}]: ${message}`;
    
    // Füge Metadaten hinzu, falls vorhanden
    if (Object.keys(metadata).length > 0) {
      msg += '\n' + JSON.stringify(metadata, null, 2);
    }
    
    return msg;
  })
);

// Logger-Instanz erstellen
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: customFormat,
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        customFormat
      )
    })
  ]
});

// Funktion zum sicheren Loggen von Datenbankdetails
logger.logDatabaseConfig = () => {
  logger.info('Datenbank-Konfiguration:', {
    host: process.env.DB_HOST || 'nicht gesetzt',
    port: process.env.DB_PORT || 'nicht gesetzt',
    database: process.env.DB_NAME || 'nicht gesetzt',
    user: process.env.DB_USER || 'nicht gesetzt',
    password: process.env.DB_PASSWORD ? '[GESCHÜTZT]' : 'nicht gesetzt'
  });
};

export default logger;
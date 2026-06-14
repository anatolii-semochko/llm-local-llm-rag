import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { logRequestStart, logRequestEnd } from '../utils/logger';

export interface RequestWithId extends Request {
  requestId: string;
  startTime: number;
}

export const requestLoggerMiddleware = (req: RequestWithId, res: Response, next: NextFunction): void => {
  req.requestId = uuidv4();
  req.startTime = Date.now();

  logRequestStart(req.requestId, req.method, req.url, req.body);

  const originalSend = res.send;
  res.send = function(data: any) {
    const duration = Date.now() - req.startTime;
    logRequestEnd(req.requestId, res.statusCode, duration);
    return originalSend.call(this, data);
  };

  next();
};
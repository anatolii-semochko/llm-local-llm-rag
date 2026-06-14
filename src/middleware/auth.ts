import { Request, Response, NextFunction } from 'express';
import { env } from '../config/environment';
import { ApiError } from '../types/api';

export interface AuthenticatedRequest extends Request {
  isAuthenticated: boolean;
}

export const authMiddleware = (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    const error: ApiError = {
      error: {
        message: 'You didn\'t provide an API key. You need to provide your API key in an Authorization header using Bearer auth (i.e. Authorization: Bearer YOUR_KEY), or as the password field (with blank username) if you\'re accessing the API from your browser and are prompted for a username and password. You can obtain an API key from https://platform.openai.com/account/api-keys.',
        type: 'invalid_request_error',
        param: null,
        code: 'missing_authorization'
      }
    };
    res.status(401).json(error);
    return;
  }

  const token = authHeader.replace('Bearer ', '');

  if (token !== env.API_KEY) {
    const error: ApiError = {
      error: {
        message: 'Incorrect API key provided: ' + token + '. You can find your API key at https://platform.openai.com/account/api-keys.',
        type: 'invalid_request_error',
        param: null,
        code: 'invalid_api_key'
      }
    };
    res.status(401).json(error);
    return;
  }

  req.isAuthenticated = true;
  next();
};
import { NextFunction, Request, RequestHandler, Response } from "express";

export function asyncHandler<P = Record<string, string>>(
    fn: (req: Request<P>, res: Response, next: NextFunction) => Promise<unknown>
): RequestHandler<P> {
    return (req: Request<P>, res: Response, next: NextFunction) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    }
}
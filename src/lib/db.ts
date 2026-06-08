import { PrismaClient } from '@prisma/client'
import { PrismaMariaDb } from '@prisma/adapter-mariadb'
import mysql from 'mysql2/promise'

// Prisma 7 requires a driver adapter
let _client: PrismaClient | null = null

function createClient(): PrismaClient {
  const pool = mysql.createPool({
    host: '127.0.0.1',
    port: 3306,
    user: 'root',
    password: 'Cjj860919',
    database: 'jiaoxi',
    waitForConnections: true,
    connectionLimit: 5,
  })
  const adapter = new PrismaMariaDb(pool as any)
  return new PrismaClient({ adapter })
}

//延迟初始化，单例模式
let _prisma: PrismaClient | undefined
export function getDb(): PrismaClient {
  if (!_prisma) {
    _prisma = createClient()
  }
  return _prisma
}

// 为了代码兼容性，提供一个代理对象
// 在 Next.js 中，每次请求应该用 getDb() 获取新实例
export const db = new Proxy({} as PrismaClient, {
  get(_target, prop) {
    const client = getDb()
    const val = (client as any)[prop]
    if (typeof val === 'function') {
      return val.bind(client)
    }
    return val
  }
})
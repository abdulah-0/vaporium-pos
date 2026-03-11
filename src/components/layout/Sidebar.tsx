'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import {
    LayoutDashboard,
    ShoppingCart,
    Package,
    Users,
    Truck,
    UserCog,
    BarChart3,
    MapPin,
    Package2,
    Award,
    FileText,
    Zap,
    Settings2,
} from 'lucide-react'

interface SidebarProps {
    tenantSlug?: string
}

export function Sidebar({ tenantSlug }: SidebarProps) {
    const pathname = usePathname()
    const baseUrl = tenantSlug ? `/${tenantSlug}` : ''

    const navigation = [
        { name: 'Dashboard', href: `${baseUrl}/dashboard`, icon: LayoutDashboard, group: 'main' },
        { name: 'POS Register', href: `${baseUrl}/sales`, icon: ShoppingCart, group: 'main' },
        { name: 'Sales History', href: `${baseUrl}/sales-history`, icon: FileText, group: 'main' },
        { name: 'Items', href: `${baseUrl}/items`, icon: Package, group: 'inventory' },
        { name: 'Receiving', href: `${baseUrl}/receiving`, icon: Package2, group: 'inventory' },
        { name: 'Locations', href: `${baseUrl}/locations`, icon: MapPin, group: 'inventory' },
        { name: 'Customers', href: `${baseUrl}/customers`, icon: Users, group: 'people' },
        { name: 'Loyalty', href: `${baseUrl}/loyalty`, icon: Award, group: 'people' },
        { name: 'Suppliers', href: `${baseUrl}/suppliers`, icon: Truck, group: 'people' },
        { name: 'Employees', href: `${baseUrl}/employees`, icon: UserCog, group: 'people' },
        { name: 'Reports', href: `${baseUrl}/reports`, icon: BarChart3, group: 'reports' },
        { name: 'Settings', href: `${baseUrl}/settings`, icon: Settings2, group: 'reports' },
    ]

    const groups = [
        { key: 'main', label: 'Sales' },
        { key: 'inventory', label: 'Inventory' },
        { key: 'people', label: 'People' },
        { key: 'reports', label: 'Analytics' },
    ]

    return (
        <div className="flex h-full w-64 flex-col" style={{
            background: 'linear-gradient(180deg, #0f0c29 0%, #302b63 50%, #24243e 100%)',
        }}>
            {/* Logo */}
            <div className="flex h-16 items-center px-5 border-b border-white/10">
                <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl"
                        style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                        <Zap className="h-5 w-5 text-white" strokeWidth={2.5} />
                    </div>
                    <div>
                        <h1 className="text-base font-bold text-white leading-tight">POS Cloud</h1>
                        <p className="text-[10px] text-purple-300 font-medium tracking-wider uppercase">Point of Sale</p>
                    </div>
                </div>
            </div>

            {/* Navigation */}
            <nav className="flex-1 overflow-y-auto py-4 px-3">
                {groups.map((group) => {
                    const groupItems = navigation.filter(item => item.group === group.key)
                    return (
                        <div key={group.key} className="mb-5">
                            <p className="mb-1.5 px-3 text-[10px] font-semibold tracking-widest uppercase text-purple-400/70">
                                {group.label}
                            </p>
                            <div className="space-y-0.5">
                                {groupItems.map((item) => {
                                    const isActive = pathname === item.href || pathname?.startsWith(item.href + '/')
                                    return (
                                        <Link
                                            key={item.name}
                                            href={item.href}
                                            className={cn(
                                                'group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-150',
                                                isActive
                                                    ? 'text-white'
                                                    : 'text-purple-200/70 hover:text-white hover:bg-white/5'
                                            )}
                                        >
                                            {isActive && (
                                                <div
                                                    className="absolute inset-0 rounded-lg"
                                                    style={{ background: 'linear-gradient(135deg, rgba(102,126,234,0.3) 0%, rgba(118,75,162,0.3) 100%)' }}
                                                />
                                            )}
                                            {isActive && (
                                                <div className="absolute left-0 top-1/2 -translate-y-1/2 h-5 w-0.5 rounded-full"
                                                    style={{ background: 'linear-gradient(180deg, #667eea, #764ba2)' }} />
                                            )}
                                            <item.icon
                                                className={cn(
                                                    'relative h-4 w-4 flex-shrink-0 transition-all duration-150',
                                                    isActive
                                                        ? 'text-purple-300'
                                                        : 'text-purple-400/50 group-hover:text-purple-300'
                                                )}
                                            />
                                            <span className="relative">{item.name}</span>
                                        </Link>
                                    )
                                })}
                            </div>
                        </div>
                    )
                })}
            </nav>

            {/* Bottom version badge */}
            <div className="px-4 py-3 border-t border-white/10">
                <p className="text-center text-[10px] text-purple-400/50">v1.0 · Cloud POS</p>
            </div>
        </div>
    )
}

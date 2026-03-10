import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Sidebar } from '@/components/layout/Sidebar'
import { Header } from '@/components/layout/Header'
import { ToastProvider } from '@/components/ui/toast'

interface TenantLayoutProps {
    children: React.ReactNode
    params: Promise<{ tenant: string }>
}

export default async function TenantLayout({ children, params }: TenantLayoutProps) {
    const supabase = await createClient()
    const { tenant: tenantSlug } = await params

    const {
        data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
        redirect('/login')
    }

    // Verify user has access to this tenant
    const { data: tenant } = await supabase
        .from('tenants')
        .select('*')
        .eq('slug', tenantSlug)
        .single()

    if (!tenant) {
        redirect('/dashboard')
    }

    // Check if user is an employee of this tenant
    const { data: employee } = await supabase
        .from('employees')
        .select('id, role_id')
        .eq('tenant_id', tenant.id)
        .eq('user_id', user.id)
        .eq('deleted', false)
        .single()

    if (!employee) {
        redirect('/dashboard')
    }

    return (
        <ToastProvider>
            <div className="flex h-screen overflow-hidden">
                <Sidebar tenantSlug={tenantSlug} />
                <div className="flex flex-1 flex-col overflow-hidden">
                    <Header user={user} tenant={tenant} />
                    <main className="flex-1 overflow-y-auto bg-gray-50 p-6">{children}</main>
                </div>
            </div>
        </ToastProvider>
    )
}

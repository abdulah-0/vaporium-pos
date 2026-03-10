'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Check, Zap, User, Building2, CreditCard, ArrowRight } from 'lucide-react'

const steps = [
    { id: 1, label: 'Account', icon: User },
    { id: 2, label: 'Business', icon: Building2 },
    { id: 3, label: 'Plan', icon: CreditCard },
]

const plans: Record<string, { name: string; price: number; tagline: string; features: string[] }> = {
    starter: {
        name: 'Starter',
        price: 29,
        tagline: 'Perfect for small shops',
        features: ['1 Location', 'Up to 500 items', 'Basic reports', 'Email support'],
    },
    professional: {
        name: 'Professional',
        price: 79,
        tagline: 'Great for growing businesses',
        features: ['3 Locations', 'Unlimited items', 'Advanced reports', 'Priority support'],
    },
    enterprise: {
        name: 'Enterprise',
        price: 199,
        tagline: 'For large-scale operations',
        features: ['Unlimited locations', 'Unlimited items', 'Custom reports', 'Dedicated support'],
    },
}

export default function SignupPage() {
    const [step, setStep] = useState(1)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const router = useRouter()
    const supabase = createClient()

    const [formData, setFormData] = useState({
        email: '',
        password: '',
        fullName: '',
        businessName: '',
        phone: '',
        plan: 'professional',
    })

    const update = (field: string, value: string) => setFormData((prev) => ({ ...prev, [field]: value }))

    const handleSignup = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)
        setError(null)

        try {
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: formData.email,
                password: formData.password,
                options: { data: { full_name: formData.fullName } },
            })

            if (authError) throw authError

            if (authData.user) {
                const slug = formData.businessName.toLowerCase().replace(/[^a-z0-9]+/g, '-')
                const { data: tenant, error: tenantError } = await supabase
                    .from('tenants')
                    .insert({
                        name: formData.businessName,
                        slug,
                        subscription_plan: formData.plan,
                        subscription_status: 'trial',
                        trial_ends_at: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
                    })
                    .select()
                    .single()

                if (tenantError) throw tenantError

                const { error: profileError } = await supabase.from('profiles').insert({
                    id: authData.user.id,
                    full_name: formData.fullName,
                    current_tenant_id: tenant.id,
                })
                if (profileError) throw profileError

                const { error: tenantUserError } = await supabase.from('tenant_users').insert({
                    tenant_id: tenant.id,
                    user_id: authData.user.id,
                    role: 'owner',
                    joined_at: new Date().toISOString(),
                })
                if (tenantUserError) throw tenantUserError

                await supabase.from('stock_locations').insert({
                    tenant_id: tenant.id,
                    location_name: 'Main Store',
                })

                setStep(4)
                setTimeout(() => router.push(`/${slug}/dashboard`), 2000)
            }
        } catch (err: unknown) {
            setError((err as Error).message || 'An error occurred during signup')
            setLoading(false)
        }
    }

    return (
        <div className="flex min-h-screen">
            {/* Left branding panel */}
            <div
                className="hidden lg:flex lg:w-2/5 flex-col justify-between p-12 relative overflow-hidden"
                style={{ background: 'linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%)' }}
            >
                <div className="absolute inset-0 overflow-hidden pointer-events-none">
                    <div className="absolute -top-40 -left-40 h-80 w-80 rounded-full opacity-20"
                        style={{ background: 'radial-gradient(circle, #667eea, transparent)' }} />
                    <div className="absolute -bottom-40 -right-40 h-80 w-80 rounded-full opacity-20"
                        style={{ background: 'radial-gradient(circle, #764ba2, transparent)' }} />
                </div>

                <div className="relative flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl"
                        style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                        <Zap className="h-5 w-5 text-white" strokeWidth={2.5} />
                    </div>
                    <span className="text-xl font-bold text-white">POS Cloud</span>
                </div>

                <div className="relative space-y-6">
                    <h2 className="text-4xl font-bold text-white leading-tight">
                        Start selling<br />
                        <span style={{
                            background: 'linear-gradient(135deg, #a78bfa, #818cf8)',
                            WebkitBackgroundClip: 'text',
                            WebkitTextFillColor: 'transparent',
                        }}>
                            smarter today.
                        </span>
                    </h2>
                    <ul className="space-y-3">
                        {['14-day free trial — no credit card', 'Set up in under 5 minutes', 'Cancel anytime', 'Full access to all features'].map((item) => (
                            <li key={item} className="flex items-center gap-2.5 text-purple-100 text-sm">
                                <div className="flex h-5 w-5 items-center justify-center rounded-full"
                                    style={{ background: 'rgba(167,139,250,0.2)' }}>
                                    <Check className="h-3 w-3 text-purple-300" strokeWidth={2.5} />
                                </div>
                                {item}
                            </li>
                        ))}
                    </ul>
                </div>
                <p className="relative text-purple-400 text-xs">© 2025 POS Cloud. All rights reserved.</p>
            </div>

            {/* Right form panel */}
            <div className="flex w-full lg:w-3/5 flex-col items-center justify-center bg-gray-50 p-8 overflow-y-auto">
                <div className="w-full max-w-md space-y-7">
                    {/* Mobile logo */}
                    <div className="flex lg:hidden items-center gap-2 justify-center">
                        <div className="flex h-9 w-9 items-center justify-center rounded-xl"
                            style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                            <Zap className="h-5 w-5 text-white" strokeWidth={2.5} />
                        </div>
                        <span className="text-xl font-bold text-gray-900">POS Cloud</span>
                    </div>

                    {step < 4 && (
                        <div className="text-center">
                            <h1 className="text-2xl font-bold text-gray-900">Create your account</h1>
                            <p className="mt-1 text-sm text-gray-500">Start your 14-day free trial</p>
                        </div>
                    )}

                    {/* Step progress */}
                    {step < 4 && (
                        <div className="flex items-center justify-center gap-2">
                            {steps.map((s, idx) => {
                                const Icon = s.icon
                                const isCompleted = step > s.id
                                const isCurrent = step === s.id
                                return (
                                    <div key={s.id} className="flex items-center">
                                        <div className="flex flex-col items-center gap-1">
                                            <div className={`flex h-9 w-9 items-center justify-center rounded-full border-2 transition-all ${isCompleted
                                                    ? 'border-purple-600 bg-purple-600 text-white'
                                                    : isCurrent
                                                        ? 'border-purple-600 bg-white text-purple-600'
                                                        : 'border-gray-200 bg-white text-gray-400'
                                                }`}>
                                                {isCompleted ? <Check className="h-4 w-4" strokeWidth={2.5} /> : <Icon className="h-4 w-4" />}
                                            </div>
                                            <span className={`text-[10px] font-medium ${isCurrent || isCompleted ? 'text-purple-600' : 'text-gray-400'}`}>
                                                {s.label}
                                            </span>
                                        </div>
                                        {idx < steps.length - 1 && (
                                            <div className={`w-12 h-0.5 mx-2 mb-4 rounded-full transition-all ${step > s.id ? 'bg-purple-600' : 'bg-gray-200'}`} />
                                        )}
                                    </div>
                                )
                            })}
                        </div>
                    )}

                    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
                        {/* Step 1 */}
                        {step === 1 && (
                            <form onSubmit={(e) => { e.preventDefault(); setStep(2) }} className="space-y-4">
                                <div className="space-y-1.5">
                                    <Label htmlFor="fullName" className="text-sm font-medium text-gray-700">Full Name</Label>
                                    <Input id="fullName" value={formData.fullName} onChange={(e) => update('fullName', e.target.value)}
                                        placeholder="John Smith" required className="h-11 bg-gray-50 border-gray-200" />
                                </div>
                                <div className="space-y-1.5">
                                    <Label htmlFor="email" className="text-sm font-medium text-gray-700">Email</Label>
                                    <Input id="email" type="email" value={formData.email} onChange={(e) => update('email', e.target.value)}
                                        placeholder="you@company.com" required className="h-11 bg-gray-50 border-gray-200" />
                                </div>
                                <div className="space-y-1.5">
                                    <Label htmlFor="password" className="text-sm font-medium text-gray-700">Password</Label>
                                    <Input id="password" type="password" value={formData.password} onChange={(e) => update('password', e.target.value)}
                                        placeholder="Min. 6 characters" required minLength={6} className="h-11 bg-gray-50 border-gray-200" />
                                </div>
                                <Button type="submit" className="w-full h-11 text-white font-semibold"
                                    style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                                    Continue <ArrowRight className="ml-2 h-4 w-4" />
                                </Button>
                            </form>
                        )}

                        {/* Step 2 */}
                        {step === 2 && (
                            <form onSubmit={(e) => { e.preventDefault(); setStep(3) }} className="space-y-4">
                                <div className="space-y-1.5">
                                    <Label htmlFor="businessName" className="text-sm font-medium text-gray-700">Business Name</Label>
                                    <Input id="businessName" value={formData.businessName} onChange={(e) => update('businessName', e.target.value)}
                                        placeholder="Acme Store" required className="h-11 bg-gray-50 border-gray-200" />
                                </div>
                                <div className="space-y-1.5">
                                    <Label htmlFor="phone" className="text-sm font-medium text-gray-700">Phone Number</Label>
                                    <Input id="phone" type="tel" value={formData.phone} onChange={(e) => update('phone', e.target.value)}
                                        placeholder="+92 300 0000000" required className="h-11 bg-gray-50 border-gray-200" />
                                </div>
                                <div className="flex gap-3">
                                    <Button type="button" variant="outline" onClick={() => setStep(1)} className="w-full h-11">Back</Button>
                                    <Button type="submit" className="w-full h-11 text-white font-semibold"
                                        style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                                        Continue <ArrowRight className="ml-2 h-4 w-4" />
                                    </Button>
                                </div>
                            </form>
                        )}

                        {/* Step 3 */}
                        {step === 3 && (
                            <form onSubmit={handleSignup} className="space-y-4">
                                <div className="space-y-2">
                                    <Label className="text-sm font-medium text-gray-700">Select Your Plan</Label>
                                    <Select value={formData.plan} onValueChange={(v) => update('plan', v)}>
                                        <SelectTrigger className="h-11 bg-gray-50 border-gray-200">
                                            <SelectValue />
                                        </SelectTrigger>
                                        <SelectContent>
                                            {Object.entries(plans).map(([key, plan]) => (
                                                <SelectItem key={key} value={key}>
                                                    {plan.name} — ${plan.price}/mo
                                                </SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>

                                {/* Plan details */}
                                <div className="rounded-xl border border-purple-100 p-4 space-y-2"
                                    style={{ background: 'linear-gradient(135deg, rgba(102,126,234,0.05), rgba(118,75,162,0.05))' }}>
                                    <div className="flex items-baseline justify-between">
                                        <p className="font-semibold text-gray-900">{plans[formData.plan].name}</p>
                                        <p className="text-sm text-gray-500">{plans[formData.plan].tagline}</p>
                                    </div>
                                    <ul className="space-y-1">
                                        {plans[formData.plan].features.map((f) => (
                                            <li key={f} className="flex items-center gap-2 text-sm text-gray-600">
                                                <Check className="h-3.5 w-3.5 text-purple-500" strokeWidth={2.5} />
                                                {f}
                                            </li>
                                        ))}
                                    </ul>
                                    <p className="text-xs text-purple-600 font-medium pt-1">✦ 14 days free — no card needed</p>
                                </div>

                                {error && (
                                    <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">{error}</div>
                                )}

                                <div className="flex gap-3">
                                    <Button type="button" variant="outline" onClick={() => setStep(2)} className="w-full h-11">Back</Button>
                                    <Button type="submit" className="w-full h-11 text-white font-semibold" disabled={loading}
                                        style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                                        {loading ? 'Creating...' : 'Start Free Trial'}
                                    </Button>
                                </div>
                            </form>
                        )}

                        {/* Step 4 - Success */}
                        {step === 4 && (
                            <div className="text-center py-6 space-y-4">
                                <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-full"
                                    style={{ background: 'linear-gradient(135deg, rgba(102,126,234,0.1), rgba(118,75,162,0.1))' }}>
                                    <div className="flex h-14 w-14 items-center justify-center rounded-full"
                                        style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
                                        <Check className="h-7 w-7 text-white" strokeWidth={2.5} />
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-xl font-bold text-gray-900">You&apos;re all set!</h3>
                                    <p className="mt-1 text-sm text-gray-500">Redirecting to your dashboard...</p>
                                </div>
                            </div>
                        )}

                        {step < 4 && (
                            <div className="mt-5 text-center text-sm text-gray-500">
                                Already have an account?{' '}
                                <a href="/login" className="font-semibold text-purple-600 hover:text-purple-700 transition-colors">
                                    Sign in
                                </a>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}

'use client'

import { useState, useEffect } from 'react'
import { useParams } from 'next/navigation'
import { Package2, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { useToast } from '@/components/ui/toast'
import { getTenantBySlug, getEmployeeId } from '@/lib/tenantUtils'
import { getReceivings } from '@/lib/services/receivingService'
import { createClient } from '@/lib/supabase/client'
import ReceivingFormDialog from '@/components/features/receiving/ReceivingFormDialog'

export default function ReceivingPage() {
    const params = useParams()
    const tenantSlug = params.tenant as string
    const [tenantId, setTenantId] = useState<string>('')
    const [employeeId, setEmployeeId] = useState<number>(0)
    const [receivings, setReceivings] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [showReceivingDialog, setShowReceivingDialog] = useState(false)
    const { showToast } = useToast()

    useEffect(() => {
        async function loadTenantAndEmployee() {
            const tenant = await getTenantBySlug(tenantSlug)
            if (tenant) {
                setTenantId(tenant.id)

                const supabase = createClient()
                const { data: { user } } = await supabase.auth.getUser()
                if (user) {
                    const empId = await getEmployeeId(user.id, tenant.id)
                    if (empId) setEmployeeId(empId)
                }
            }
        }
        loadTenantAndEmployee()
    }, [tenantSlug])

    useEffect(() => {
        if (tenantId) {
            loadReceivings()
        }
    }, [tenantId])

    const loadReceivings = async () => {
        setLoading(true)
        try {
            const data = await getReceivings(tenantId)
            setReceivings(data)
        } catch (error) {
            console.error('Error loading receivings:', error)
            showToast('error', 'Failed to load receivings')
        } finally {
            setLoading(false)
        }
    }

    const handleReceivingSaved = () => {
        setShowReceivingDialog(false)
        loadReceivings()
    }

    const calculateTotal = (receiving: any) => {
        return receiving.receivings_items?.reduce((sum: number, item: any) => {
            const itemTotal = item.item_unit_price * item.quantity_purchased
            const discount = itemTotal * (item.discount_percent / 100)
            return sum + (itemTotal - discount)
        }, 0) || 0
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Receiving</h1>
                    <p className="text-gray-500 mt-1">Purchase orders and stock receiving</p>
                </div>
                <Button onClick={() => setShowReceivingDialog(true)} className="bg-blue-600 hover:bg-blue-700">
                    <Plus className="h-4 w-4 mr-2" />
                    New Receiving
                </Button>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Package2 className="h-5 w-5" />
                        Receiving History ({receivings.length})
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    {loading ? (
                        <div className="text-center py-12 text-gray-500">Loading receivings...</div>
                    ) : receivings.length === 0 ? (
                        <div className="text-center py-12">
                            <Package2 className="mx-auto h-12 w-12 text-gray-300 mb-4" />
                            <p className="text-gray-500">No receivings found</p>
                            <p className="text-sm text-gray-400 mt-1">Create your first receiving to get started</p>
                        </div>
                    ) : (
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>ID</TableHead>
                                    <TableHead>Date</TableHead>
                                    <TableHead>Supplier</TableHead>
                                    <TableHead>Reference</TableHead>
                                    <TableHead>Items</TableHead>
                                    <TableHead className="text-right">Total</TableHead>
                                    <TableHead>Payment</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {receivings.map((receiving) => (
                                    <TableRow key={receiving.id}>
                                        <TableCell className="font-mono">#{receiving.id}</TableCell>
                                        <TableCell>
                                            {new Date(receiving.receiving_time).toLocaleDateString()}
                                        </TableCell>
                                        <TableCell>
                                            {receiving.supplier?.company_name || '-'}
                                        </TableCell>
                                        <TableCell>{receiving.reference || '-'}</TableCell>
                                        <TableCell>
                                            <Badge variant="outline">
                                                {receiving.receivings_items?.length || 0} items
                                            </Badge>
                                        </TableCell>
                                        <TableCell className="text-right font-medium">
                                            ${calculateTotal(receiving).toFixed(2)}
                                        </TableCell>
                                        <TableCell>
                                            {receiving.payment_type ? (
                                                <Badge>{receiving.payment_type}</Badge>
                                            ) : (
                                                '-'
                                            )}
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    )}
                </CardContent>
            </Card>

            <ReceivingFormDialog
                open={showReceivingDialog}
                onOpenChange={setShowReceivingDialog}
                tenantId={tenantId}
                employeeId={employeeId}
                onSaved={handleReceivingSaved}
            />
        </div>
    )
}

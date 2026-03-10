'use client'

import { useState, useEffect } from 'react'
import { useForm, useFieldArray } from 'react-hook-form'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { Plus, Trash2 } from 'lucide-react'
import { useToast } from '@/components/ui/toast'
import { createReceiving, getSuppliers, ReceivingInput } from '@/lib/services/receivingService'
import { getItems } from '@/lib/services/itemsService'
import { getStockLocations } from '@/lib/services/inventoryService'

interface ReceivingFormDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    tenantId: string
    employeeId: number
    onSaved: () => void
}

export default function ReceivingFormDialog({
    open,
    onOpenChange,
    tenantId,
    employeeId,
    onSaved,
}: ReceivingFormDialogProps) {
    const [loading, setLoading] = useState(false)
    const [suppliers, setSuppliers] = useState<any[]>([])
    const [items, setItems] = useState<any[]>([])
    const [locations, setLocations] = useState<any[]>([])
    const { showToast } = useToast()

    const { register, handleSubmit, control, watch, setValue, reset } = useForm<ReceivingInput>({
        defaultValues: {
            supplier_id: undefined,
            reference: '',
            payment_type: '',
            comment: '',
            items: [],
        },
    })

    const { fields, append, remove } = useFieldArray({
        control,
        name: 'items',
    })

    const receivingItems = watch('items')

    useEffect(() => {
        if (open && tenantId) {
            loadData()
        }
    }, [open, tenantId])

    const loadData = async () => {
        try {
            const [suppliersData, itemsData, locationsData] = await Promise.all([
                getSuppliers(tenantId),
                getItems(tenantId),
                getStockLocations(tenantId),
            ])
            setSuppliers(suppliersData)
            setItems(itemsData)
            setLocations(locationsData)
        } catch (error) {
            console.error('Error loading data:', error)
        }
    }

    const handleAddItem = () => {
        append({
            item_id: 0,
            quantity_purchased: 1,
            item_cost_price: 0,
            item_unit_price: 0,
            discount_percent: 0,
            item_location: locations[0]?.id || 1,
        })
    }

    const calculateTotal = () => {
        return receivingItems.reduce((sum, item) => {
            const itemTotal = item.item_unit_price * item.quantity_purchased
            const discount = itemTotal * (item.discount_percent / 100)
            return sum + (itemTotal - discount)
        }, 0)
    }

    const onSubmit = async (data: ReceivingInput) => {
        if (data.items.length === 0) {
            showToast('error', 'Please add at least one item')
            return
        }

        setLoading(true)
        try {
            await createReceiving(data, tenantId, employeeId)
            showToast('success', 'Receiving created successfully')
            reset()
            onSaved()
        } catch (error) {
            console.error('Error creating receiving:', error)
            showToast('error', 'Failed to create receiving')
        } finally {
            setLoading(false)
        }
    }

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="max-w-5xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle>New Receiving</DialogTitle>
                </DialogHeader>

                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Supplier</Label>
                            <Select
                                value={watch('supplier_id')?.toString()}
                                onValueChange={(value) => setValue('supplier_id', parseInt(value))}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="Select supplier" />
                                </SelectTrigger>
                                <SelectContent>
                                    {suppliers.map((supplier) => (
                                        <SelectItem key={supplier.id} value={supplier.id.toString()}>
                                            {supplier.company_name}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>

                        <div className="space-y-2">
                            <Label>Reference (PO #, Invoice #)</Label>
                            <Input {...register('reference')} placeholder="Optional" />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Payment Type</Label>
                            <Select
                                value={watch('payment_type')}
                                onValueChange={(value) => setValue('payment_type', value)}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="Select payment type" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="cash">Cash</SelectItem>
                                    <SelectItem value="card">Card</SelectItem>
                                    <SelectItem value="check">Check</SelectItem>
                                    <SelectItem value="credit">Credit</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>

                        <div className="space-y-2">
                            <Label>Comment</Label>
                            <Input {...register('comment')} placeholder="Optional notes" />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <div className="flex items-center justify-between">
                            <Label>Items</Label>
                            <Button type="button" onClick={handleAddItem} size="sm">
                                <Plus className="h-4 w-4 mr-2" />
                                Add Item
                            </Button>
                        </div>

                        {fields.length > 0 && (
                            <div className="border rounded-lg overflow-hidden">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>Item</TableHead>
                                            <TableHead>Location</TableHead>
                                            <TableHead>Qty</TableHead>
                                            <TableHead>Cost</TableHead>
                                            <TableHead>Price</TableHead>
                                            <TableHead>Disc%</TableHead>
                                            <TableHead>Total</TableHead>
                                            <TableHead></TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {fields.map((field, index) => {
                                            const item = receivingItems[index]
                                            const itemTotal = item.item_unit_price * item.quantity_purchased
                                            const discount = itemTotal * (item.discount_percent / 100)
                                            const total = itemTotal - discount

                                            return (
                                                <TableRow key={field.id}>
                                                    <TableCell>
                                                        <Select
                                                            value={item.item_id?.toString()}
                                                            onValueChange={(value) => {
                                                                const selectedItem = items.find(i => i.id === parseInt(value))
                                                                setValue(`items.${index}.item_id`, parseInt(value))
                                                                if (selectedItem) {
                                                                    setValue(`items.${index}.item_cost_price`, selectedItem.cost_price)
                                                                    setValue(`items.${index}.item_unit_price`, selectedItem.unit_price)
                                                                }
                                                            }}
                                                        >
                                                            <SelectTrigger className="w-[200px]">
                                                                <SelectValue placeholder="Select item" />
                                                            </SelectTrigger>
                                                            <SelectContent>
                                                                {items.map((item) => (
                                                                    <SelectItem key={item.id} value={item.id.toString()}>
                                                                        {item.name}
                                                                    </SelectItem>
                                                                ))}
                                                            </SelectContent>
                                                        </Select>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Select
                                                            value={item.item_location?.toString()}
                                                            onValueChange={(value) => setValue(`items.${index}.item_location`, parseInt(value))}
                                                        >
                                                            <SelectTrigger className="w-[120px]">
                                                                <SelectValue />
                                                            </SelectTrigger>
                                                            <SelectContent>
                                                                {locations.map((loc) => (
                                                                    <SelectItem key={loc.id} value={loc.id.toString()}>
                                                                        {loc.location_name}
                                                                    </SelectItem>
                                                                ))}
                                                            </SelectContent>
                                                        </Select>
                                                    </TableCell>
                                                    <TableCell>
                                                        <Input
                                                            type="number"
                                                            className="w-20"
                                                            {...register(`items.${index}.quantity_purchased`, { valueAsNumber: true })}
                                                        />
                                                    </TableCell>
                                                    <TableCell>
                                                        <Input
                                                            type="number"
                                                            step="0.01"
                                                            className="w-24"
                                                            {...register(`items.${index}.item_cost_price`, { valueAsNumber: true })}
                                                        />
                                                    </TableCell>
                                                    <TableCell>
                                                        <Input
                                                            type="number"
                                                            step="0.01"
                                                            className="w-24"
                                                            {...register(`items.${index}.item_unit_price`, { valueAsNumber: true })}
                                                        />
                                                    </TableCell>
                                                    <TableCell>
                                                        <Input
                                                            type="number"
                                                            step="0.01"
                                                            className="w-20"
                                                            {...register(`items.${index}.discount_percent`, { valueAsNumber: true })}
                                                        />
                                                    </TableCell>
                                                    <TableCell className="font-medium">
                                                        ${total.toFixed(2)}
                                                    </TableCell>
                                                    <TableCell>
                                                        <Button
                                                            type="button"
                                                            variant="ghost"
                                                            size="sm"
                                                            onClick={() => remove(index)}
                                                        >
                                                            <Trash2 className="h-4 w-4 text-red-600" />
                                                        </Button>
                                                    </TableCell>
                                                </TableRow>
                                            )
                                        })}
                                    </TableBody>
                                </Table>
                            </div>
                        )}

                        {fields.length > 0 && (
                            <div className="flex justify-end">
                                <div className="text-lg font-bold">
                                    Total: ${calculateTotal().toFixed(2)}
                                </div>
                            </div>
                        )}
                    </div>

                    <DialogFooter>
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => onOpenChange(false)}
                            disabled={loading}
                        >
                            Cancel
                        </Button>
                        <Button type="submit" disabled={loading}>
                            {loading ? 'Creating...' : 'Create Receiving'}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    )
}
